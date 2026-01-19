# frozen_string_literal: true

# Slow Query Logger
# 100ms以上のクエリを検出してログに出力する

if Rails.env.development? || Rails.env.production?
  ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
    # スキーママイグレーションクエリは除外
    next if payload[:name] == "SCHEMA"

    duration = (finish - start) * 1000 # ミリ秒に変換

    # 100ms以上のクエリを検出
    if duration > 100
      sql = payload[:sql].truncate(500) # SQLが長すぎる場合は切り詰め
      message = "[SLOW QUERY] #{duration.round(2)}ms - #{sql}"

      Rails.logger.warn message

      # 本番環境では専用ログファイルに出力
      if Rails.env.production?
        slow_query_log_path = Rails.root.join("log", "slow_query.log")
        slow_query_logger = Logger.new(slow_query_log_path, "daily")
        slow_query_logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{msg}\n"
        end
        slow_query_logger.warn message
      end
    end
  end

  Rails.logger.info "[SlowQueryLogger] Slow query detection enabled (threshold: 100ms)"
end
