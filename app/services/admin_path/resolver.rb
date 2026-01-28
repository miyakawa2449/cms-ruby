module AdminPath
  class Resolver
    DEFAULT_PATH = "admin-secure-panel-miyakawa2449"

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
