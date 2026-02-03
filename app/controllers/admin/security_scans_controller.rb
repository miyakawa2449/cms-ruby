# frozen_string_literal: true

module Admin
  # Controller for viewing security scan results
  class SecurityScansController < BaseController
    before_action :set_security_scan, only: [ :show ]

    def index
      @security_scans = SecurityScan.recent.page(params[:page]).per(20)
    end

    def show
      @vulnerabilities = @security_scan.vulnerabilities.by_severity.page(params[:page]).per(20)
    end

    private

    def set_security_scan
      @security_scan = SecurityScan.find(params[:id])
    end
  end
end
