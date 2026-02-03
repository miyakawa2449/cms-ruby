# frozen_string_literal: true

module Security
  # Job for generating weekly security reports
  class WeeklyReportJob < ApplicationJob
    queue_as :default

    def perform
      Security::ReporterService.new.generate_weekly_report
    rescue StandardError => e
      Rails.logger.error("Weekly security report failed: #{e.message}")
      raise
    end
  end
end
