# frozen_string_literal: true

# Model for storing security scan results
class SecurityScan < ApplicationRecord
  has_many :vulnerabilities, dependent: :destroy

  enum :scan_type, { brakeman: 0, bundler_audit: 1 }
  enum :status, { pending: 0, running: 1, completed: 2, failed: 3 }

  validates :scan_type, presence: true
  validates :status, presence: true
  validates :scanned_at, presence: true

  scope :recent, -> { order(scanned_at: :desc) }
  scope :with_vulnerabilities, -> { joins(:vulnerabilities).distinct }

  def high_severity_count
    vulnerabilities.where(severity: [ :critical, :high ]).count
  end

  def summary
    {
      total: vulnerabilities.count,
      critical: vulnerabilities.where(severity: :critical).count,
      high: vulnerabilities.where(severity: :high).count,
      medium: vulnerabilities.where(severity: :medium).count,
      low: vulnerabilities.where(severity: :low).count
    }
  end
end
