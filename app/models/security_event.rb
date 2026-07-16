# frozen_string_literal: true

# セキュリティイベントの永続化（S1-7 P0-4）
# SecurityLoggerが記録する認証・攻撃系イベントをDBに保存し、
# 週次セキュリティレポート（Security::ReporterService）の集計元にする
class SecurityEvent < ApplicationRecord
  EVENT_TYPES = %w[
    login_success
    login_failure
    logout
    account_locked
    account_unlocked
    unauthorized_access
    csrf_error
    rate_limit_exceeded
    request_blocked
  ].freeze

  # デフォルトの保持期間（これより古いものは日次ジョブで削除）
  RETENTION_PERIOD = 90.days

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :occurred_at, presence: true

  before_validation { self.occurred_at ||= Time.current }

  scope :of_type, ->(types) { where(event_type: types) }
  scope :occurred_between, ->(start_time, end_time) { where(occurred_at: start_time..end_time) }

  def self.purge_old!(older_than: RETENTION_PERIOD.ago)
    where(occurred_at: ...older_than).delete_all
  end
end
