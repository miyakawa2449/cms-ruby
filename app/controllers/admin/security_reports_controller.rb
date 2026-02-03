# frozen_string_literal: true

module Admin
  # Controller for viewing and downloading security reports
  class SecurityReportsController < BaseController
    before_action :set_security_report, only: [ :show, :download ]

    def index
      @security_reports = SecurityReport.recent.page(params[:page]).per(20)
    end

    def show
    end

    def download
      send_data generate_report_pdf,
                filename: @security_report.pdf_filename,
                type: "application/pdf"
    end

    private

    def set_security_report
      @security_report = SecurityReport.find(params[:id])
    end

    def generate_report_pdf
      report_data = @security_report.data || {}
      scans = report_data["scans"] || {}
      vulns = report_data["vulnerabilities"] || {}
      severity = vulns["by_severity"] || {}

      Prawn::Document.new(page_size: "A4", margin: 50) do |pdf|
        pdf.text "Security Report", size: 20, style: :bold
        pdf.move_down 10
        pdf.text "Period: #{@security_report.period_start.to_date} - #{@security_report.period_end.to_date}"
        pdf.text "Generated at: #{@security_report.generated_at&.strftime('%Y-%m-%d %H:%M:%S') || '-'}"
        pdf.move_down 20

        pdf.text "Scan Summary", style: :bold
        pdf.text "Total scans: #{scans['total'] || 0}"
        pdf.text "Brakeman: #{scans['brakeman'] || 0}"
        pdf.text "bundler-audit: #{scans['bundler_audit'] || 0}"
        pdf.text "Completed: #{scans['completed'] || 0}"
        pdf.text "Failed: #{scans['failed'] || 0}"
        pdf.move_down 15

        pdf.text "Vulnerability Summary", style: :bold
        pdf.text "Total: #{vulns['total'] || 0}"
        pdf.text "New: #{vulns['new'] || 0}"
        pdf.text "Fixed: #{vulns['fixed'] || 0}"
        pdf.move_down 5
        pdf.text "By Severity:"
        pdf.text "  Critical: #{severity['critical'] || 0}"
        pdf.text "  High: #{severity['high'] || 0}"
        pdf.text "  Medium: #{severity['medium'] || 0}"
        pdf.text "  Low: #{severity['low'] || 0}"
        pdf.text "  Info: #{severity['info'] || 0}"
      end.render
    end
  end
end
