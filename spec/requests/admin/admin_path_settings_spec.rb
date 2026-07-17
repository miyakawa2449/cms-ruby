# frozen_string_literal: true

require "rails_helper"

# 管理画面URL変更（セキュリティ機能）。実際のURL変更はAdminPath::Updaterが担い
# 専用specでカバー済みのため、ここではコントローラの分岐（成功/失敗/サインアウト）を検証する
RSpec.describe "Admin::AdminPathSettings", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user
    host! "localhost"
  end

  describe "GET /admin/admin_path_settings/edit" do
    it "現在のパスと変更履歴を表示する" do
      get edit_admin_admin_path_settings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("管理画面URL")
    end
  end

  describe "PUT /admin/admin_path_settings" do
    it "成功時はサインアウトしてログイン画面へリダイレクトする" do
      updater = instance_double(AdminPath::Updater, call: { success: true })
      allow(AdminPath::Updater).to receive(:new).and_return(updater)

      put admin_admin_path_settings_path, params: { new_path: "new-secret-path", reason: "定期変更" }

      expect(response).to redirect_to(new_admin_user_session_path)
      expect(AdminPath::Updater).to have_received(:new).with(
        hash_including(admin_user: admin_user, new_path: "new-secret-path", change_type: :manual)
      )

      # サインアウトされていること（管理画面に入れない）
      get edit_admin_admin_path_settings_path
      expect(response).not_to have_http_status(:ok)
    end

    it "失敗時はアラートを表示して設定画面に戻す" do
      updater = instance_double(AdminPath::Updater, call: { success: false, error: "invalid path" })
      allow(AdminPath::Updater).to receive(:new).and_return(updater)

      put admin_admin_path_settings_path, params: { new_path: "bad path" }

      expect(response).to redirect_to(edit_admin_admin_path_settings_path)
      expect(flash[:alert]).to include("invalid path")
    end
  end

  describe "POST /admin/admin_path_settings/emergency_rotation" do
    it "ランダムな緊急パスでUpdaterを呼びサインアウトする" do
      updater = instance_double(AdminPath::Updater, call: { success: true })
      allow(AdminPath::Updater).to receive(:new).and_return(updater)

      post emergency_rotation_admin_admin_path_settings_path

      expect(response).to redirect_to(new_admin_user_session_path)
      expect(AdminPath::Updater).to have_received(:new).with(
        hash_including(change_type: :emergency, new_path: match(/\Aemergency-admin-[0-9a-f]{12}\z/))
      )
    end

    it "失敗時はアラートを表示して設定画面に戻す" do
      updater = instance_double(AdminPath::Updater, call: { success: false, error: "rotation failed" })
      allow(AdminPath::Updater).to receive(:new).and_return(updater)

      post emergency_rotation_admin_admin_path_settings_path

      expect(response).to redirect_to(edit_admin_admin_path_settings_path)
      expect(flash[:alert]).to include("rotation failed")
    end
  end
end
