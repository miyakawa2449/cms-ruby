module AdminPath
  class Resolver
    # 未設定時の無害なデフォルト。秘匿したい場合はENV(ADMIN_PATH)か
  # 管理画面のURL変更機能（DB履歴が優先される）で設定する
  DEFAULT_PATH = "admin"

    def self.current_path
      unless Object.const_defined?("AdminPathHistory")
        return ENV.fetch("ADMIN_PATH", DEFAULT_PATH)
      end

      latest = AdminPathHistory.order(created_at: :desc).limit(1).pick(:new_path)
      latest.presence || ENV.fetch("ADMIN_PATH", DEFAULT_PATH)
    rescue StandardError => e
      Rails.logger.warn("AdminPath::Resolver fallback: #{e.class} #{e.message}")
      ENV.fetch("ADMIN_PATH", DEFAULT_PATH)
    end
  end
end
