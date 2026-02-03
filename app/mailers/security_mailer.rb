# frozen_string_literal: true

# Mailer for security audit notifications
class SecurityMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "noreply@example.test") }

  # Notify when Brakeman detects issues
  def brakeman_issues(audit_log)
    @audit_log = audit_log
    @issues = audit_log.issues_summary || []
    @issues_count = audit_log.issues_count

    mail(
      to: ENV.fetch("SECURITY_AUDIT_EMAIL", ENV.fetch("ADMIN_EMAIL", "admin@example.test")),
      subject: "[Security] Brakeman detected #{@issues_count} vulnerabilities"
    )
  end

  # Notify when bundler-audit detects issues
  def bundler_audit_issues(audit_log)
    @audit_log = audit_log
    @issues = audit_log.issues_summary || []
    @issues_count = audit_log.issues_count

    mail(
      to: ENV.fetch("SECURITY_AUDIT_EMAIL", ENV.fetch("ADMIN_EMAIL", "admin@example.test")),
      subject: "[Security] bundler-audit detected #{@issues_count} vulnerabilities"
    )
  end

  # Weekly security report
  def weekly_report(report)
    @report = report
    @period = report[:period]
    @brakeman_stats = report[:brakeman] || {}
    @bundler_audit_stats = report[:bundler_audit] || {}

    mail(
      to: ENV.fetch("SECURITY_AUDIT_EMAIL", ENV.fetch("ADMIN_EMAIL", "admin@example.test")),
      subject: "[Security] Weekly Security Report: #{@period}"
    )
  end

  # Notify when audit completes with no issues
  def audit_success(audit_type)
    @audit_type = audit_type
    @completed_at = Time.current

    mail(
      to: ENV.fetch("SECURITY_AUDIT_EMAIL", ENV.fetch("ADMIN_EMAIL", "admin@example.test")),
      subject: "[Security] #{audit_type.humanize} audit completed - No issues found"
    )
  end

  # Security alert for high/critical vulnerabilities (Phase 7.4)
  def security_alert(scan)
    @scan = scan
    @vulnerabilities = scan.vulnerabilities.where(severity: [ :critical, :high ])
    @summary = scan.summary

    mail(
      to: ENV.fetch("SECURITY_AUDIT_EMAIL", ENV.fetch("ADMIN_EMAIL", "admin@example.test")),
      subject: "[SECURITY ALERT] #{scan.scan_type.titleize}: #{@vulnerabilities.count} High/Critical Issues"
    )
  end

  # Alert for high error rate (Phase 7.4)
  def high_error_rate_alert(rate:, total_requests:, error_requests:)
    @rate = rate
    @total_requests = total_requests
    @error_requests = error_requests
    @timestamp = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "admin@example.test"),
      subject: "[ALERT] High Error Rate Detected: #{(rate * 100).round(2)}%"
    )
  end

  # Alert for traffic spike (Phase 7.4)
  def traffic_spike_alert(requests_per_minute:)
    @requests_per_minute = requests_per_minute
    @timestamp = Time.current

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "admin@example.test"),
      subject: "[ALERT] Traffic Spike Detected: #{requests_per_minute} req/min"
    )
  end
end
