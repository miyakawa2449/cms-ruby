module AdminUsers
  # パスキー（WebAuthn）によるログイン（S1-6 Phase A）。
  # パスキー自体が多要素（デバイス所持 + 生体/PIN）のため、成功時はOTPを要求しない
  class PasskeySessionsController < ApplicationController
    layout false

    # POST /{admin_path}/passkey_session/options
    # 認証チャレンジの発行（未ログイン状態で呼ばれる）
    def options
      get_options = WebAuthn::Credential.options_for_get(user_verification: "required")

      session[:passkey_authentication_challenge] = get_options.challenge
      render json: get_options
    end

    # POST /{admin_path}/passkey_session
    def create
      challenge = session.delete(:passkey_authentication_challenge)
      webauthn_credential = WebAuthn::Credential.from_get(credential_params)

      passkey = PasskeyCredential.find_by(external_id: webauthn_credential.id)
      unless passkey
        render json: { error: "登録されていないパスキーです" }, status: :unauthorized
        return
      end

      webauthn_credential.verify(
        challenge.to_s,
        public_key: passkey.public_key,
        sign_count: passkey.sign_count
      )

      passkey.record_usage!(sign_count: webauthn_credential.sign_count)
      sign_in(:admin_user, passkey.admin_user)

      render json: { redirect_url: admin_root_path }
    rescue WebAuthn::SignCountVerificationError, PasskeyCredential::CloneDetectedError
      # 認証器のカウンタ逆行 = パスキー複製の疑い（クローン検知）。ログインを拒否し警告する
      PasskeyMailer.clone_detected(passkey.admin_user, passkey.nickname).deliver_later
      Rails.logger.warn "[Passkey] クローン疑い検知: credential=#{passkey.id}"
      render json: { error: "このパスキーは安全でない可能性があるため使用できません" }, status: :unauthorized
    rescue WebAuthn::Error => e
      Rails.logger.warn "[Passkey] ログイン検証失敗: #{e.class}: #{e.message}"
      render json: { error: "パスキー認証に失敗しました" }, status: :unauthorized
    end

    private

    def credential_params
      params.require(:credential).to_unsafe_h
    end
  end
end
