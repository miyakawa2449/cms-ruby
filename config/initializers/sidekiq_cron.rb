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
    }
  )
end
