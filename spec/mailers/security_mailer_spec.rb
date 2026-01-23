# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityMailer, type: :mailer do
  let(:audit_log) do
    double("SecurityAuditLog",
      id: 1,
      audit_type: "brakeman",
      status: "warning",
      issues_count: 3,
      issues_summary: [
        { "warning_type" => "SQL Injection", "message" => "Possible SQL injection" },
        { "warning_type" => "XSS", "message" => "Possible cross-site scripting" }
      ],
      created_at: Time.current
    )
  end

  describe "#brakeman_issues" do
    let(:mail) { described_class.brakeman_issues(audit_log) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Security] Brakeman detected 3 vulnerabilities")
      expect(mail.to).to include(ENV.fetch("SECURITY_AUDIT_EMAIL", ENV.fetch("ADMIN_EMAIL", "admin@example.test")))
    end

    it "renders the body with issue details" do
      expect(body).to include("Brakeman")
      expect(body).to include("3")
      expect(body).to include("SQL Injection")
    end
  end

  describe "#bundler_audit_issues" do
    let(:bundler_log) do
      double("SecurityAuditLog",
        id: 2,
        audit_type: "bundler_audit",
        status: "warning",
        issues_count: 2,
        issues_summary: [
          { "gem" => "nokogiri", "version" => "1.10.0", "advisory" => "CVE-2020-1234" }
        ],
        created_at: Time.current
      )
    end
    let(:mail) { described_class.bundler_audit_issues(bundler_log) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Security] bundler-audit detected 2 vulnerabilities")
    end

    it "renders the body with gem details" do
      expect(body).to include("nokogiri")
      expect(body).to include("CVE-2020-1234")
    end
  end

  describe "#weekly_report" do
    let(:report) do
      {
        period: "2026-01-16 - 2026-01-23",
        brakeman: { total_audits: 7, total_issues: 2 },
        bundler_audit: { total_audits: 7, total_issues: 0 }
      }
    end
    let(:mail) { described_class.weekly_report(report) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Security] Weekly Security Report: 2026-01-16 - 2026-01-23")
    end

    it "renders the body with report summary" do
      expect(body).to include("2026-01-16 - 2026-01-23")
      expect(body).to include("7")
      expect(body).to include("2")
    end
  end

  describe "#audit_success" do
    let(:mail) { described_class.audit_success("brakeman") }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Security] Brakeman audit completed - No issues found")
    end

    it "renders the body with success message" do
      expect(body).to include("Brakeman")
      expect(body).to include("問題は検出されませんでした")
    end
  end
end
