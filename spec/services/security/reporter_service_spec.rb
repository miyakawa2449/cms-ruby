# frozen_string_literal: true

require "rails_helper"

RSpec.describe Security::ReporterService do
  describe "#generate_weekly_report" do
    let(:service) { described_class.new }

    before do
      allow(SecurityMailer).to receive_message_chain(:weekly_report, :deliver_later)
    end

    it "creates a security report" do
      expect { service.generate_weekly_report }.to change(SecurityReport, :count).by(1)
    end

    it "sets report attributes correctly" do
      report = service.generate_weekly_report

      expect(report.report_type).to eq("weekly")
      expect(report.status).to eq("completed")
      expect(report.generated_at).to be_present
    end

    it "collects scan data" do
      create(:security_scan, :brakeman, scanned_at: 3.days.ago)
      create(:security_scan, :bundler_audit, scanned_at: 2.days.ago)

      report = service.generate_weekly_report

      expect(report.data["scans"]["total"]).to eq(2)
      expect(report.data["scans"]["brakeman"]).to eq(1)
      expect(report.data["scans"]["bundler_audit"]).to eq(1)
    end

    it "collects vulnerability data" do
      scan = create(:security_scan, scanned_at: 3.days.ago)
      create(:vulnerability, :critical, security_scan: scan, created_at: 3.days.ago)
      create(:vulnerability, :high, security_scan: scan, created_at: 3.days.ago)
      create(:vulnerability, :medium, security_scan: scan, fixed: true, created_at: 3.days.ago)

      report = service.generate_weekly_report

      expect(report.data["vulnerabilities"]["total"]).to eq(3)
      expect(report.data["vulnerabilities"]["new"]).to eq(2)
      expect(report.data["vulnerabilities"]["fixed"]).to eq(1)
      expect(report.data["vulnerabilities"]["by_severity"]["critical"]).to eq(1)
      expect(report.data["vulnerabilities"]["by_severity"]["high"]).to eq(1)
    end

    it "sends report email" do
      service.generate_weekly_report

      expect(SecurityMailer).to have_received(:weekly_report)
    end
  end
end
