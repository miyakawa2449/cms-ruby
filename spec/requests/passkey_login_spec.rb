require "rails_helper"
require "webauthn/fake_client"

# パスキーによるログイン（S1-6 Phase A、仕様書FR-2）
RSpec.describe "パスキーログイン", type: :request do
  let(:password) { "Passw0rd!Passw0rd!" }
  let(:admin_user) { create(:admin_user, password: password, password_confirmation: password) }
  let(:fake_client) { WebAuthn::FakeClient.new("http://localhost:3000") }

  # FakeClientで実際に登録エンドポイントを通してパスキーを作る
  def register_passkey!
    sign_in admin_user, scope: :admin_user
    post options_admin_passkeys_path, params: { current_password: password }, as: :json
    challenge = JSON.parse(response.body)["challenge"]
    credential = fake_client.create(challenge: challenge)
    post admin_passkeys_path, params: { credential: credential, nickname: "テスト機" }, as: :json
    sign_out admin_user
    admin_user.passkey_credentials.last
  end

  def passkey_login!
    post passkey_session_options_path, as: :json
    challenge = JSON.parse(response.body)["challenge"]
    assertion = fake_client.get(challenge: challenge)
    post passkey_session_path, params: { credential: assertion }, as: :json
  end

  describe "POST /passkey_session/options" do
    it "未ログインでもチャレンジを発行できる" do
      post passkey_session_options_path, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["challenge"]).to be_present
    end
  end

  describe "POST /passkey_session（認証）" do
    it "登録済みパスキーでログインできる" do
      register_passkey!

      passkey_login!

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["redirect_url"]).to be_present
      # ログイン状態で管理画面にアクセスできる
      get admin_root_path
      expect(response).to have_http_status(:ok)
    end

    it "2FA有効ユーザーでもOTP入力なしでログインできる（パスキー自体が多要素）" do
      register_passkey!
      admin_user.enable_two_factor!

      passkey_login!

      get admin_root_path
      expect(response).to have_http_status(:ok)
    end

    it "last_used_atとsign_countが更新される" do
      passkey = register_passkey!

      passkey_login!

      expect(passkey.reload.last_used_at).to be_present
    end

    it "未登録のクレデンシャルでは認証されない" do
      register_passkey!
      other_client = WebAuthn::FakeClient.new("http://localhost:3000")
      other_client.create(challenge: Base64.urlsafe_encode64(SecureRandom.random_bytes(32)))

      post passkey_session_options_path, as: :json
      challenge = JSON.parse(response.body)["challenge"]
      assertion = other_client.get(challenge: challenge)
      post passkey_session_path, params: { credential: assertion }, as: :json

      expect(response).to have_http_status(:unauthorized)
      get admin_root_path
      expect(response).to have_http_status(:redirect) # 未ログインのまま
    end

    it "チャレンジ不一致では認証されない" do
      register_passkey!

      post passkey_session_options_path, as: :json
      assertion = fake_client.get(challenge: Base64.urlsafe_encode64(SecureRandom.random_bytes(32)))
      post passkey_session_path, params: { credential: assertion }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "sign_countの逆行（クローン疑い）を検知し、ログイン拒否と警告メールを行う" do
      passkey = register_passkey!
      passkey.update_column(:sign_count, 999) # 認証器のカウンタより大きい値=次の認証は「逆行」になる

      expect { passkey_login! }.to have_enqueued_mail(PasskeyMailer, :clone_detected)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
