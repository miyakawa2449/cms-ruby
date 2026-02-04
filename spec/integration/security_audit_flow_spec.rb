# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Security audit flows", type: :integration do
  describe "scan -> notification flow" do
    let(:results) do
      {
        "warnings" => [
          {
            "warning_type" => "SQL Injection",
            "confidence" => "High",
            "message" => "Possible SQL injection",
            "file" => "app/models/user.rb",
            "line" => 42
          }
        ]
      }
    end

    it "creates scan, vulnerabilities, and triggers alert mail" do
      allow(SecurityMailer).to receive_message_chain(:security_alert, :deliver_later)
      allow(SlackNotifier).to receive(:enabled?).and_return(false)

      scan = Security::ScannerService.new(scan_type: "brakeman", results: results).process

      expect(scan).to be_completed
      expect(scan.vulnerabilities.count).to eq(1)
      expect(SecurityMailer).to have_received(:security_alert)
    end
  end

  describe "report generation flow" do
    it "generates weekly report with scan and vulnerability data" do
      Vulnerability.delete_all
      SecurityScan.delete_all
      scan = create(:security_scan, scanned_at: 3.days.ago)
      create(:vulnerability, :high, security_scan: scan, created_at: 3.days.ago)

      allow(SecurityMailer).to receive_message_chain(:weekly_report, :deliver_later)

      report = Security::ReporterService.new(
        start_date: 4.days.ago,
        end_date: 2.days.ago
      ).generate_weekly_report

      expect(report).to be_completed
      expect(report.data.dig("scans", "total")).to eq(1)
      expect(report.data.dig("vulnerabilities", "total")).to eq(1)
    end
  end
end
