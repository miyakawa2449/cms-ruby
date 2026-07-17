# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::TwoFactorAuth", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user
    host! "localhost"
  end

  describe "GET /admin/two_factor_auth" do
    context "when 2FA is not enabled" do
      it "returns success" do
        get admin_two_factor_auth_path
        expect(response).to be_successful
      end

      it "shows 2FA status section" do
        get admin_two_factor_auth_path
        expect(response.body).to include("二要素認証")
      end
    end
  end

  describe "GET /admin/two_factor_auth/new" do
    context "when 2FA is not enabled" do
      it "returns success" do
        get new_admin_two_factor_auth_path
        expect(response).to be_successful
      end

      it "shows QR code section" do
        get new_admin_two_factor_auth_path
        expect(response.body).to include("QRコード")
      end

      it "generates OTP secret for user" do
        get new_admin_two_factor_auth_path
        admin_user.reload
        expect(admin_user.otp_secret).to be_present
      end
    end
  end

  # S1-7 P5: 状態変更系（有効化・無効化・バックアップコード再生成）のカバレッジ追加
  describe "POST /admin/two_factor_auth（有効化）" do
    before do
      admin_user.update!(otp_secret: AdminUser.generate_otp_secret)
    end

    it "正しいパスワードとOTPで2FAを有効化しバックアップコードを表示する" do
      allow(SlackNotifier).to receive(:notify_2fa_changed)

      post admin_two_factor_auth_path, params: {
        current_password: TestCredentials.admin_password,
        otp_code: admin_user.current_otp
      }

      expect(response).to have_http_status(:ok)
      expect(admin_user.reload.two_factor_enabled?).to be true
      expect(SlackNotifier).to have_received(:notify_2fa_changed).with(admin_user, "enabled")
    end

    it "OTPが誤っていると有効化しない" do
      post admin_two_factor_auth_path, params: {
        current_password: TestCredentials.admin_password,
        otp_code: "000000"
      }

      expect(response).to redirect_to(new_admin_two_factor_auth_path)
      expect(admin_user.reload.two_factor_enabled?).to be false
    end

    it "パスワードが誤っていると処理自体を拒否する" do
      post admin_two_factor_auth_path, params: {
        current_password: "wrong-password",
        otp_code: admin_user.current_otp
      }

      expect(admin_user.reload.two_factor_enabled?).to be false
    end
  end

  describe "DELETE /admin/two_factor_auth（無効化）" do
    before do
      admin_user.update!(otp_secret: AdminUser.generate_otp_secret, otp_required_for_login: true)
    end

    it "正しいパスワードとOTPで2FAを無効化する" do
      allow(SlackNotifier).to receive(:notify_2fa_changed)

      delete admin_two_factor_auth_path, params: {
        current_password: TestCredentials.admin_password,
        otp_code: admin_user.current_otp
      }

      expect(response).to redirect_to(admin_two_factor_auth_path)
      expect(admin_user.reload.two_factor_enabled?).to be false
      expect(SlackNotifier).to have_received(:notify_2fa_changed).with(admin_user, "disabled")
    end

    it "OTPが誤っていると無効化しない" do
      delete admin_two_factor_auth_path, params: {
        current_password: TestCredentials.admin_password,
        otp_code: "000000"
      }

      expect(admin_user.reload.two_factor_enabled?).to be true
    end
  end

  describe "POST /admin/two_factor_auth/regenerate_backup_codes" do
    it "2FA有効時にバックアップコードを再生成する" do
      admin_user.update!(otp_secret: AdminUser.generate_otp_secret, otp_required_for_login: true)

      post regenerate_backup_codes_admin_two_factor_auth_path, params: {
        current_password: TestCredentials.admin_password
      }

      expect(response).to have_http_status(:ok)
      expect(admin_user.reload.backup_codes_count).to be > 0
    end

    it "2FA無効時は拒否する" do
      post regenerate_backup_codes_admin_two_factor_auth_path, params: {
        current_password: TestCredentials.admin_password
      }

      expect(response).to redirect_to(admin_two_factor_auth_path)
    end
  end

  describe "廃止されたverify画面（監査M-3）" do
    it "verifyルートは存在しない（2FA検証はDeviseのログインフローが担う）" do
      expect(Rails.application.routes.url_helpers).not_to respond_to(:verify_admin_two_factor_auth_path)
    end
  end
end
