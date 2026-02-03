# frozen_string_literal: true

module Security
  # Service for processing security scan results
  class ScannerService
    def initialize(scan_type:, results:)
      @scan_type = scan_type
      @results = results
    end

    def process
      scan = create_scan
      parse_results(scan)
      notify_if_vulnerabilities(scan)
      scan
    rescue StandardError => e
      Rails.logger.error "Security scan processing failed: #{e.message}"
      create_failed_scan(e.message)
    end

    private

    def create_scan
      SecurityScan.create!(
        scan_type: @scan_type,
        status: "completed",
        raw_results: sanitize_results(@results),
        scanned_at: Time.current
      )
    end

    def create_failed_scan(error_message)
      SecurityScan.create!(
        scan_type: @scan_type,
        status: "failed",
        raw_results: {},
        scanned_at: Time.current,
        error_message: error_message
      )
    end

    def parse_results(scan)
      case @scan_type.to_s
      when "brakeman"
        parse_brakeman_results(scan)
      when "bundler_audit"
        parse_bundler_audit_results(scan)
      end
    end

    def parse_brakeman_results(scan)
      warnings = @results["warnings"] || []

      warnings.each do |warning|
        scan.vulnerabilities.create!(
          severity: map_brakeman_severity(warning["confidence"]),
          title: warning["warning_type"],
          description: warning["message"],
          file_path: warning["file"],
          line_number: warning["line"],
          cve_id: nil,
          fixed: false
        )
      end
    end

    def parse_bundler_audit_results(scan)
      results = @results["results"] || []

      results.each do |result|
        advisories = result["advisories"] || []
        gem_info = result["gem"] || {}

        advisories.each do |advisory|
          scan.vulnerabilities.create!(
            severity: map_bundler_audit_severity(advisory["criticality"]),
            title: advisory["title"],
            description: advisory["description"] || "No description",
            gem_name: gem_info["name"],
            gem_version: gem_info["version"],
            cve_id: advisory["cve"],
            patched_versions: Array(advisory["patched_versions"]).join(", "),
            fixed: false
          )
        end
      end
    end

    def notify_if_vulnerabilities(scan)
      return if scan.vulnerabilities.empty?

      scope = scan.vulnerabilities.where(severity: notification_severities(scan))
      return if scope.empty?

      send_security_alert(scan, scope)
    end

    def send_security_alert(scan, high_severity)
      SecurityMailer.security_alert(scan).deliver_later

      SlackNotifier.notify_security_issue(scan) if SlackNotifier.enabled?
    rescue StandardError => e
      Rails.logger.error "Failed to send security alert: #{e.message}"
    end

    def map_brakeman_severity(confidence)
      case confidence
      when "High" then :high
      when "Medium" then :medium
      when "Weak" then :low
      else :info
      end
    end

    def map_bundler_audit_severity(criticality)
      case criticality
      when "Critical" then :critical
      when "High" then :high
      when "Medium" then :medium
      when "Low" then :low
      else :info
      end
    end

    def notification_severities(scan)
      return [ :critical, :high, :medium ] if scan.scan_type.to_s == "bundler_audit"

      [ :critical, :high ]
    end

    def sanitize_results(results)
      return {} unless results.is_a?(Hash)

      results.deep_dup.tap do |sanitized|
        sanitized.deep_transform_values! do |value|
          if value.is_a?(String) && sensitive_pattern?(value)
            "[REDACTED]"
          else
            value
          end
        end
      end
    end

    def sensitive_pattern?(value)
      value.match?(/password|token|secret|key|credential|api_key/i)
    end
  end
end
