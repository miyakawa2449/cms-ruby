return if Rails.env.test?

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
