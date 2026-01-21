# frozen_string_literal: true

# Security event logging service (structured JSON logs)
class SecurityLogger
  class << self
    def log_login_success(user, request)
      log_event(
        event: "login_success",
        user_id: user&.id,
        email: user&.email,
        **request_metadata(request)
      )
    end

    def log_login_failure(email, request, reason: "invalid_credentials")
      log_event(
        event: "login_failure",
        email: email,
        reason: reason,
        **request_metadata(request)
      )
    end

    def log_logout(user, request)
      log_event(
        event: "logout",
        user_id: user&.id,
        email: user&.email,
        **request_metadata(request)
      )
    end

    def log_account_locked(user, request)
      log_event(
        event: "account_locked",
        user_id: user&.id,
        email: user&.email,
        severity: "warning",
        **request_metadata(request)
      )
    end

    def log_account_unlocked(user, request = nil)
      log_event(
        event: "account_unlocked",
        user_id: user&.id,
        email: user&.email,
        **request_metadata(request)
      )
    end

    def log_unauthorized_access(path, request)
      log_event(
        event: "unauthorized_access",
        path: path,
        severity: "warning",
        **request_metadata(request)
      )
    end

    def log_rate_limit_exceeded(discriminator, request)
      log_event(
        event: "rate_limit_exceeded",
        discriminator: discriminator,
        path: request&.path,
        severity: "warning",
        **request_metadata(request)
      )
    end

    private

    def request_metadata(request)
      return {} unless request

      ip = if request.respond_to?(:remote_ip)
        request.remote_ip
      elsif request.respond_to?(:ip)
        request.ip
      elsif request.respond_to?(:env)
        request.env["REMOTE_ADDR"]
      end

      user_agent = if request.respond_to?(:user_agent)
        request.user_agent
      elsif request.respond_to?(:env)
        request.env["HTTP_USER_AGENT"]
      end

      {
        ip: ip,
        user_agent: user_agent
      }
    end

    def log_event(event_data)
      severity = event_data.delete(:severity) || "info"
      log_data = {
        timestamp: Time.current.iso8601,
        environment: Rails.env,
        **event_data
      }

      case severity
      when "warning"
        Rails.logger.warn("[SECURITY] #{log_data.to_json}")
      when "error"
        Rails.logger.error("[SECURITY] #{log_data.to_json}")
      else
        Rails.logger.info("[SECURITY] #{log_data.to_json}")
      end
    end
  end
end
