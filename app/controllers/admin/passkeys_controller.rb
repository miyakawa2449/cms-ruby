module Admin
  # パスキー（WebAuthn）の登録・管理（S1-6 Phase A）
  class PasskeysController < Admin::BaseController
    # POST /admin/passkeys/options
    # 登録チャレンジの発行。なりすまし登録を防ぐためパスワード再確認を要求する（仕様FR-1）
    def options
      unless current_admin_user.valid_password?(params[:current_password])
        render json: { error: "パスワードが正しくありません" }, status: :unprocessable_entity
        return
      end

      creation_options = WebAuthn::Credential.options_for_create(
        user: {
          id: current_admin_user.webauthn_id,
          name: current_admin_user.email
        },
        exclude: current_admin_user.passkey_credentials.pluck(:external_id),
        authenticator_selection: {
          resident_key: "required",     # discoverable credential（メール入力なしログイン用）
          user_verification: "required" # 生体認証/PINを必須にする
        }
      )

      session[:passkey_registration_challenge] = creation_options.challenge
      render json: creation_options
    end

    # GET /admin/passkeys
    def index
      @passkeys = current_admin_user.passkey_credentials.recently_used_first
    end

    # POST /admin/passkeys
    def create
      challenge = session.delete(:passkey_registration_challenge)
      webauthn_credential = WebAuthn::Credential.from_create(credential_params)
      webauthn_credential.verify(challenge.to_s)

      passkey = current_admin_user.passkey_credentials.create!(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        nickname: params[:nickname].presence || default_nickname,
        sign_count: webauthn_credential.sign_count
      )

      PasskeyMailer.registered(current_admin_user, passkey.nickname).deliver_later
      render json: { id: passkey.id, nickname: passkey.nickname }, status: :created
    rescue WebAuthn::Error => e
      Rails.logger.warn "[Passkey] 登録検証失敗: #{e.class}: #{e.message}"
      render json: { error: "パスキーの検証に失敗しました。もう一度お試しください" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join("、") }, status: :unprocessable_entity
    end

    # DELETE /admin/passkeys/:id
    def destroy
      passkey = current_admin_user.passkey_credentials.find(params[:id])

      # 締め出し防止（仕様FR-3）: 最後の1つは、パスワード+2FAという
      # 代替ログイン手段が確保されている場合のみ削除を許可する
      if current_admin_user.passkey_credentials.count == 1 && !current_admin_user.two_factor_enabled?
        redirect_to admin_passkeys_path,
          alert: "最後のパスキーは削除できません（2FAが無効のため、削除するとパスワードのみの防御になります。先に2FAを有効にするか、別のパスキーを登録してください）。"
        return
      end

      nickname = passkey.nickname
      passkey.destroy!

      PasskeyMailer.removed(current_admin_user, nickname).deliver_later
      redirect_to admin_passkeys_path, notice: "パスキー「#{nickname}」を削除しました。"
    end

    private

    def credential_params
      params.require(:credential).to_unsafe_h
    end

    def default_nickname
      "パスキー（#{Time.current.strftime('%Y/%m/%d %H:%M')}登録）"
    end
  end
end
