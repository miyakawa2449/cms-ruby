# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SecurityScans", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    host! "localhost"
    sign_in admin_user, scope: :admin_user
  end

  describe "GET /admin/.../security_scans" do
    let!(:scan) { create(:security_scan, :with_vulnerabilities) }

    it "returns success" do
      get admin_security_scans_path

      expect(response).to have_http_status(:success)
    end

    it "displays security scans" do
      get admin_security_scans_path

      expect(response.body).to include("セキュリティスキャン")
    end
  end

  describe "GET /admin/.../security_scans/:id" do
    let!(:scan) { create(:security_scan, :with_vulnerabilities) }

    it "returns success" do
      get admin_security_scan_path(scan)

      expect(response).to have_http_status(:success)
    end

    it "displays scan details" do
      get admin_security_scan_path(scan)

      expect(response.body).to include("スキャン情報")
      expect(response.body).to include("脆弱性サマリー")
    end
  end

  context "when not authenticated" do
    before { sign_out admin_user }

    it "redirects to login" do
      get admin_security_scans_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("sign_in")
    end
  end
end
