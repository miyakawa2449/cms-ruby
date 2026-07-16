require "rails_helper"
require "webauthn/fake_client"

# パスキー登録・管理フロー（S1-6 Phase A、仕様書FR-1/FR-3/FR-4）
RSpec.describe "Admin::Passkeys", type: :request do
  let(:admin_user) { create(:admin_user, password: "Passw0rd!Passw0rd!", password_confirmation: "Passw0rd!Passw0rd!") }
  let(:fake_client) { WebAuthn::FakeClient.new("http://localhost:3000") }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe "リカバリー警告バナー（仕様FR-3）" do
    it "パスキーが1つだけのとき管理画面全体にバナーが表示される" do
      create(:passkey_credential, admin_user: admin_user)

      get admin_dashboard_path

      expect(response.body).to include("もう1つ")
    end

    it "パスキーが2つあればバナーは表示されない" do
      create_list(:passkey_credential, 2, admin_user: admin_user)

      get admin_dashboard_path

      expect(response.body).not_to include("もう1つ")
    end
  end

  describe "GET /admin/passkeys（一覧）" do
    it "登録済みパスキーが最終使用日時付きで表示される" do
      create(:passkey_credential, admin_user: admin_user, nickname: "iPhone", last_used_at: 1.day.ago)

      get admin_passkeys_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("iPhone")
    end
  end

  describe "POST /admin/passkeys/options（登録チャレンジ発行）" do
    it "正しいパスワードでチャレンジを発行しセッションに保存する" do
      post options_admin_passkeys_path, params: { current_password: "Passw0rd!Passw0rd!" }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["challenge"]).to be_present
      expect(session[:passkey_registration_challenge]).to be_present
    end

    it "パスワードが誤っていると発行しない" do
      post options_admin_passkeys_path, params: { current_password: "wrong" }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:passkey_registration_challenge]).to be_nil
    end

    it "登録済みパスキーは除外リストに含まれる（二重登録防止）" do
      existing = create(:passkey_credential, admin_user: admin_user)

      post options_admin_passkeys_path, params: { current_password: "Passw0rd!Passw0rd!" }, as: :json

      json = JSON.parse(response.body)
      exclude_ids = json["excludeCredentials"].map { |c| c["id"] }
      expect(exclude_ids).to include(existing.external_id)
    end
  end

  describe "POST /admin/passkeys（登録検証）" do
    def issue_challenge
      post options_admin_passkeys_path, params: { current_password: "Passw0rd!Passw0rd!" }, as: :json
      JSON.parse(response.body)["challenge"]
    end

    it "正しいアテステーションでパスキーが登録され通知が送られる" do
      challenge = issue_challenge
      credential = fake_client.create(challenge: challenge)

      expect {
        post admin_passkeys_path, params: { credential: credential, nickname: "テストiPhone" }, as: :json
      }.to change(admin_user.passkey_credentials, :count).by(1)
        .and have_enqueued_mail(PasskeyMailer, :registered)

      expect(response).to have_http_status(:created)
      expect(admin_user.passkey_credentials.last.nickname).to eq("テストiPhone")
    end

    it "チャレンジ不一致では登録されない" do
      issue_challenge
      credential = fake_client.create(challenge: Base64.urlsafe_encode64(SecureRandom.random_bytes(32)))

      expect {
        post admin_passkeys_path, params: { credential: credential, nickname: "不正" }, as: :json
      }.not_to change(PasskeyCredential, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "チャレンジ未発行（セッションなし）では登録されない" do
      credential = fake_client.create(challenge: Base64.urlsafe_encode64(SecureRandom.random_bytes(32)))

      post admin_passkeys_path, params: { credential: credential, nickname: "不正" }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/passkeys/:id" do
    it "パスキーを削除し通知が送られる" do
      credential = create(:passkey_credential, admin_user: admin_user)
      create(:passkey_credential, admin_user: admin_user) # 2つ目（最終ガード回避）

      expect {
        delete admin_passkey_path(credential)
      }.to change(PasskeyCredential, :count).by(-1)
        .and have_enqueued_mail(PasskeyMailer, :removed)
    end

    it "最後の1つは2FAが無効だと削除できない（締め出し防止・仕様FR-3）" do
      credential = create(:passkey_credential, admin_user: admin_user)

      expect {
        delete admin_passkey_path(credential)
      }.not_to change(PasskeyCredential, :count)

      expect(flash[:alert]).to include("削除できません")
    end

    it "最後の1つでも2FAが有効なら削除できる（パスワード+2FAが残るため）" do
      admin_user.enable_two_factor!
      credential = create(:passkey_credential, admin_user: admin_user)

      expect {
        delete admin_passkey_path(credential)
      }.to change(PasskeyCredential, :count).by(-1)
    end

    it "他の管理者のパスキーは削除できない" do
      other_admin = create(:admin_user)
      other_credential = create(:passkey_credential, admin_user: other_admin)

      delete admin_passkey_path(other_credential)

      expect(response).to have_http_status(:not_found)
      expect(PasskeyCredential.exists?(other_credential.id)).to be true
    end
  end
end
