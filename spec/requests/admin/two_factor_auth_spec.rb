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

  describe "GET /admin/two_factor_auth/verify" do
    before do
      admin_user.enable_two_factor!
    end

    it "returns success" do
      get verify_admin_two_factor_auth_path
      expect(response).to be_successful
    end

    it "shows verification form" do
      get verify_admin_two_factor_auth_path
      expect(response.body).to include("認証コード")
    end
  end
end
