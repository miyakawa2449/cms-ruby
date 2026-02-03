# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SecurityReports", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    host! "localhost"
    sign_in admin_user, scope: :admin_user
  end

  describe "GET /admin/.../security_reports" do
    let!(:report) { create(:security_report, :with_data) }

    it "returns success" do
      get admin_security_reports_path

      expect(response).to have_http_status(:success)
    end

    it "displays security reports" do
      get admin_security_reports_path

      expect(response.body).to include("セキュリティレポート")
    end
  end

  describe "GET /admin/.../security_reports/:id" do
    let!(:report) { create(:security_report, :with_data) }

    it "returns success" do
      get admin_security_report_path(report)

      expect(response).to have_http_status(:success)
    end

    it "displays report details" do
      get admin_security_report_path(report)

      expect(response.body).to include("レポート情報")
    end
  end

  describe "GET /admin/.../security_reports/:id/download" do
    let!(:report) { create(:security_report, :with_data) }

    it "returns pdf file" do
      get download_admin_security_report_path(report)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/pdf")
    end

    it "returns a non-empty pdf" do
      get download_admin_security_report_path(report)

      expect(response.body).to be_present
      expect(response.body.bytesize).to be > 100
    end
  end

  context "when not authenticated" do
    before { sign_out admin_user }

    it "redirects to login" do
      get admin_security_reports_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("sign_in")
    end
  end
end
