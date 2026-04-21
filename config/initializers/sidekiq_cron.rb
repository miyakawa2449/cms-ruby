return if Rails.env.test?
return if ENV["SECRET_KEY_BASE_DUMMY"].present?
return if ENV["DISABLE_SIDEKIQ_CRON"] == "1"
return if ENV["REDIS_URL"].blank?

if defined?(Sidekiq::Cron)
  Sidekiq::Cron::Job.load_from_hash(
    "admin_path_rotation" => {
      "class" => "AdminPath::RotationJob",
      "cron" => "0 */6 * * *",
      "queue" => "default",
      "description" => "管理画面URL自動ローテーション"
    },
    "daily_backup" => {
      "class" => "Backup::DailyBackupJob",
      "cron" => "0 3 * * *",    # 毎日午前3時 JST
      "queue" => "backup",
      "description" => "日次バックアップ"
    },
    "weekly_backup" => {
      "class" => "Backup::WeeklyBackupJob",
      "cron" => "0 3 * * 0",    # 毎週日曜日午前3時 JST
      "queue" => "backup",
      "description" => "週次バックアップ"
    },
    "monthly_backup" => {
      "class" => "Backup::MonthlyBackupJob",
      "cron" => "0 3 1 * *",    # 毎月1日午前3時 JST
      "queue" => "backup",
      "description" => "月次バックアップ"
    }
  )
end
