module AdminPath
  class RotationJob < ApplicationJob
    queue_as :default

    def perform
      return unless rotation_enabled?
      return unless rotation_due?

      admin_user = AdminUser.first
      new_path = generate_rotation_path

      result = AdminPath::Updater.new(
        admin_user: admin_user,
        new_path: new_path,
        change_type: :auto_rotation,
        reason: "自動ローテーション"
      ).call

      if result[:success]
        Rails.logger.info("Admin path auto-rotated: #{result[:new_path]}")
      else
        Rails.logger.error("Admin path auto-rotation failed: #{result[:error]}")
      end
    end

    private

    def rotation_enabled?
      ENV.fetch("ADMIN_PATH_ROTATION_ENABLED", "false") == "true"
    end

    def rotation_due?
      last_rotation = AdminPathHistory.order(created_at: :desc).first
      return true unless last_rotation

      frequency = ENV.fetch("ADMIN_PATH_ROTATION_FREQUENCY", "monthly")
      case frequency
      when "weekly"
        last_rotation.created_at < 1.week.ago
      when "monthly"
        last_rotation.created_at < 1.month.ago
      when "quarterly"
        last_rotation.created_at < 3.months.ago
      else
        false
      end
    end

    def generate_rotation_path
      timestamp = Time.current.strftime("%Y%m%d")
      random = SecureRandom.hex(4)
      "admin-secure-#{timestamp}-#{random}"
    end
  end
end
