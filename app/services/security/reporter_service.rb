# frozen_string_literal: true

module Security
  # Service for generating security reports
  class ReporterService
    def initialize(start_date: 1.week.ago, end_date: Time.current)
      @start_date = start_date
      @end_date = end_date
    end

    def generate_weekly_report
      report = SecurityReport.create!(
        report_type: "weekly",
        status: "generating",
        period_start: @start_date,
        period_end: @end_date
      )

      collect_scan_data(report)
      collect_vulnerability_data(report)
      collect_incident_data(report)

      report.update!(
        status: "completed",
        generated_at: Time.current
      )

      send_report(report)

      report
    rescue StandardError => e
      Rails.logger.error "Weekly security report failed: #{e.message}"
      report&.update(status: "failed") if report&.persisted?
      raise
    end

    private

    def collect_scan_data(report)
      scans = SecurityScan.where(scanned_at: @start_date..@end_date)

      report.data["scans"] = {
        total: scans.count,
        brakeman: scans.brakeman.count,
        bundler_audit: scans.bundler_audit.count,
        completed: scans.completed.count,
        failed: scans.failed.count
      }

      report.save!
    end

    def collect_vulnerability_data(report)
      vulnerabilities = Vulnerability.where(created_at: @start_date..@end_date)

      report.data["vulnerabilities"] = {
        total: vulnerabilities.count,
        new: vulnerabilities.unfixed.count,
        fixed: vulnerabilities.where(fixed: true).count,
        by_severity: {
          critical: vulnerabilities.critical.count,
          high: vulnerabilities.high.count,
          medium: vulnerabilities.medium.count,
          low: vulnerabilities.low.count,
          info: vulnerabilities.info.count
        }
      }

      # Unfixed vulnerabilities summary
      report.data["unfixed_vulnerabilities"] = vulnerabilities.unfixed.by_severity.limit(10).map do |v|
        {
          id: v.id,
          title: v.title,
          severity: v.severity,
          cve_id: v.cve_id,
          created_at: v.created_at.iso8601
        }
      end

      report.save!
    end

    def collect_incident_data(report)
      report.data["incidents"] = {
        failed_logins: count_failed_logins,
        blocked_ips: count_blocked_ips,
        csrf_errors: count_csrf_errors,
        unauthorized_access: count_unauthorized_access
      }

      report.save!
    end

    def send_report(report)
      SecurityMailer.weekly_report(format_report_for_email(report)).deliver_later
    rescue StandardError => e
      Rails.logger.error "Failed to send weekly report: #{e.message}"
    end

    def format_report_for_email(report)
      {
        period: "#{report.period_start.to_date} - #{report.period_end.to_date}",
        brakeman: {
          scans: report.data.dig("scans", "brakeman") || 0,
          issues: count_brakeman_issues
        },
        bundler_audit: {
          scans: report.data.dig("scans", "bundler_audit") || 0,
          issues: count_bundler_audit_issues
        },
        vulnerabilities: report.data["vulnerabilities"] || {},
        incidents: report.data["incidents"] || {}
      }
    end

    def count_failed_logins
      security_events_in_period.of_type("login_failure").count
    end

    # スロットル超過またはブロックされたユニークIP数
    def count_blocked_ips
      security_events_in_period
        .of_type(%w[rate_limit_exceeded request_blocked])
        .distinct
        .count(:ip)
    end

    def count_csrf_errors
      security_events_in_period.of_type("csrf_error").count
    end

    def count_unauthorized_access
      security_events_in_period.of_type("unauthorized_access").count
    end

    def security_events_in_period
      SecurityEvent.occurred_between(@start_date, @end_date)
    end

    def count_brakeman_issues
      SecurityScan.brakeman
                  .where(scanned_at: @start_date..@end_date)
                  .joins(:vulnerabilities)
                  .count
    end

    def count_bundler_audit_issues
      SecurityScan.bundler_audit
                  .where(scanned_at: @start_date..@end_date)
                  .joins(:vulnerabilities)
                  .count
    end
  end
end
