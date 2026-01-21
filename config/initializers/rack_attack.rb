# Rack::Attack configuration for Portfolio CMS
# Rate limiting and security rules

class Rack::Attack
  if Rails.env.production?
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
    )
  else
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  admin_path = ENV.fetch("ADMIN_PATH", "admin-secure-panel-miyakawa2449")

  safelist("allow from admin IPs") do |req|
    admin_ips = ENV.fetch("ADMIN_WHITELIST_IPS", "").split(",").map(&:strip)
    admin_ips.include?(req.ip) if admin_ips.any?
  end

  # Throttle login attempts by IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path.end_with?("/sign_in") && req.post?
      req.ip
    end
  end

  # Throttle password reset attempts by IP
  throttle("password_resets/ip", limit: 5, period: 1.hour) do |req|
    if req.path.end_with?("/password") && req.post?
      req.ip
    end
  end

  # Throttle API requests by IP (authenticated vs unauthenticated)
  throttle("api/authenticated", limit: 300, period: 1.minute) do |req|
    if req.path.start_with?("/api") && req.env["warden"]&.user
      req.env["warden"].user.id
    end
  end

  throttle("api/unauthenticated", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api") && !req.env["warden"]&.user
      req.ip
    end
  end

  # Throttle contact form submissions
  throttle("contact_form/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/contacts" && req.post?
      req.ip
    end
  end

  # Throttle admin access attempts by IP
  throttle("admin/ip", limit: 10, period: 1.minute) do |req|
    if req.path.start_with?("/#{admin_path}") && !req.env["warden"]&.user
      req.ip
    end
  end

  # General request throttling (loose limit)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Block suspicious requests
  blocklist("block suspicious requests") do |req|
    query = CGI.unescape(req.query_string.to_s)
    query =~ /(\.|%2e)(\.|%2e)(\/|%2f|\\|%5c)/i ||
      query =~ /union.*select/i ||
      query =~ /\b(exec|execute|select|insert|update|delete|drop|create)\b/i
  end

  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ {
        error: "Too Many Requests",
        message: "リクエスト数が制限を超えました。しばらく待ってから再度お試しください。",
        retry_after: retry_after
      }.to_json ]
    ]
  end

  self.blocklisted_responder = lambda do |_req|
    [
      403,
      { "Content-Type" => "application/json" },
      [ { error: "Forbidden", message: "アクセスが拒否されました。" }.to_json ]
    ]
  end
end

ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _request_id, payload|
  request = payload[:request]
  matched = request&.env&.[]( "rack.attack.matched")
  next unless matched

  SecurityLogger.log_rate_limit_exceeded(matched, request)
end

if Rails.env.production? || Rails.env.staging? || Rails.env.test?
  Rails.application.config.middleware.use Rack::Attack
end
