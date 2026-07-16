# frozen_string_literal: true

require "rails_helper"

# セキュリティイベントのDB記録（S1-7 P0-4）
# 週次レポートの incidents 集計の元データが実際に記録されることを確認する
RSpec.describe "セキュリティイベント記録", type: :request do
  describe "ログイン失敗" do
    it "誤ったパスワードでのログイン試行がSecurityEventに記録される" do
      admin_user = create(:admin_user)

      expect {
        post admin_user_session_path, params: {
          admin_user: { email: admin_user.email, password: "wrong-password" }
        }
      }.to change(SecurityEvent.of_type("login_failure"), :count).by(1)

      expect(SecurityEvent.last.email).to eq(admin_user.email)
    end
  end

  describe "CSRFエラー" do
    around do |example|
      # 他specがContactsControllerへ直接代入すると継承が切れるため、両方に明示設定する
      original_base = ActionController::Base.allow_forgery_protection
      original_contacts = ContactsController.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      ContactsController.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original_base
      ContactsController.allow_forgery_protection = original_contacts
    end

    it "無効なトークンでのPOSTがSecurityEventに記録される" do
      expect {
        post contacts_path, params: { contact: { name: "test" } }
      }.to change(SecurityEvent.of_type("csrf_error"), :count).by(1)

      # show_exceptions=:rescuableのためInvalidAuthenticityTokenは422になる
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "無効なトークンでは問い合わせが作成されない（CSRF穴の回帰テスト）" do
      expect {
        post contacts_path, params: {
          contact: { name: "攻撃者", email: "a@example.com", subject: "spam", message: "spam" }
        }
      }.not_to change(Contact, :count)
    end
  end
end
