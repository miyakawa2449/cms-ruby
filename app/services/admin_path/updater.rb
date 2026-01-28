module AdminPath
  class Updater
    RESERVED_PATHS = %w[
      admin administrator root system api health
      login logout signin signout register signup
    ].freeze
    MAX_PATH_LENGTH = 64
    PATH_FORMAT_REGEX = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    def initialize(admin_user:, new_path:, change_type: :manual, reason: nil)
      @admin_user = admin_user
      @new_path = new_path.to_s.strip.downcase
      @change_type = change_type
      @reason = reason
      @old_path = ENV.fetch("ADMIN_PATH", "admin")
    end

    def call
      validate!
      update_env_file!
      create_history!
      reload_routes!
      send_notifications!

      { success: true, new_path: @new_path }
    rescue StandardError => e
      Rails.logger.error("AdminPath::Updater failed: #{e.message}")
      { success: false, error: e.message }
    end

    private

    def validate!
      raise ArgumentError, "New path cannot be empty" if @new_path.blank?
      raise ArgumentError, "New path is reserved" if RESERVED_PATHS.include?(@new_path)
      if @new_path.length > MAX_PATH_LENGTH
        raise ArgumentError, "New path is too long (max #{MAX_PATH_LENGTH})"
      end
      unless @new_path.match?(PATH_FORMAT_REGEX)
        raise ArgumentError, "New path must be alphanumeric with single hyphens"
      end
      raise ArgumentError, "New path is same as current" if @new_path == @old_path
    end

    def update_env_file!
      env_file = Rails.root.join(".env.production")
      return unless File.exist?(env_file)

      content = File.read(env_file)

      if content.match?(/^ADMIN_PATH=/)
        content.gsub!(/^ADMIN_PATH=.*$/, "ADMIN_PATH=#{@new_path}")
      else
        content += "\nADMIN_PATH=#{@new_path}\n"
      end

      File.write(env_file, content)
      ENV["ADMIN_PATH"] = @new_path
    end

    def create_history!
      AdminPathHistory.create!(
        admin_user: @admin_user,
        old_path: @old_path,
        new_path: @new_path,
        change_type: @change_type,
        ip_address: @admin_user.try(:current_sign_in_ip),
        reason: @reason,
        notified_at: Time.current
      )
    end

    def reload_routes!
      Rails.application.reload_routes!
    end

    def send_notifications!
      # AdminPathMailer uses positional arguments
      AdminPathMailer.path_changed(
        @admin_user, @old_path, @new_path, @change_type.to_s
      ).deliver_later

      # SlackNotifier uses positional arguments
      SlackNotifier.notify_admin_path_changed(
        @admin_user, @old_path, @new_path, @change_type.to_s
      )
    end
  end
end
