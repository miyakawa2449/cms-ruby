# frozen_string_literal: true

require "rails_helper"

RSpec.describe Security::ReporterService do
  describe "#generate_weekly_report" do
    let(:service) { described_class.new }

    before do
      allow(SecurityMailer).to receive(:weekly_report)
        .and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
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

    it "collects incident data from security events" do
      # 期間内: ログイン失敗2件
      create(:security_event, event_type: "login_failure", occurred_at: 2.days.ago)
      create(:security_event, event_type: "login_failure", occurred_at: 3.days.ago)
      # 期間外は数えない
      create(:security_event, event_type: "login_failure", occurred_at: 2.weeks.ago)

      # ブロックIP: 同一IPの複数イベントは1と数える（ユニークIP数）
      create(:security_event, event_type: "rate_limit_exceeded", ip: "198.51.100.1", occurred_at: 1.day.ago)
      create(:security_event, event_type: "rate_limit_exceeded", ip: "198.51.100.1", occurred_at: 2.days.ago)
      create(:security_event, event_type: "request_blocked", ip: "198.51.100.2", occurred_at: 1.day.ago)

      create(:security_event, event_type: "csrf_error", occurred_at: 1.day.ago)
      create(:security_event, event_type: "unauthorized_access", occurred_at: 1.day.ago)

      report = service.generate_weekly_report
      incidents = report.data["incidents"]

      expect(incidents["failed_logins"]).to eq(2)
      expect(incidents["blocked_ips"]).to eq(2)
      expect(incidents["csrf_errors"]).to eq(1)
      expect(incidents["unauthorized_access"]).to eq(1)
    end
  end
end
