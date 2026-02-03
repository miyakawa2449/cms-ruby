# frozen_string_literal: true

# Model for storing security reports
class SecurityReport < ApplicationRecord
  enum :report_type, { weekly: 0, monthly: 1, custom: 2 }
  enum :status, { pending: 0, generating: 1, completed: 2, failed: 3 }

  validates :report_type, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true

  scope :recent, -> { order(generated_at: :desc) }

  def pdf_filename
    "security-report-#{period_start.to_date}-#{period_end.to_date}.pdf"
  end
end
