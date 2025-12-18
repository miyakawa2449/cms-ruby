# Rack::Attack configuration for Portfolio CMS
# Rate limiting and security rules

class Rack::Attack
  # Cache configuration for throttling
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Throttle login attempts by IP
  # Matches any Devise sign_in path (e.g., /admin-secure-panel-miyakawa2449/sign_in)
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path.end_with?('/sign_in') && req.post?
      req.ip
    end
  end

  # Throttle password reset attempts by IP
  # Matches Devise password reset path
  throttle('password_resets/ip', limit: 5, period: 1.hour) do |req|
    if req.path.end_with?('/password') && req.post?
      req.ip
    end
  end

  # Throttle API requests by IP
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api')
  end

  # Throttle contact form submissions
  throttle('contact_form/ip', limit: 5, period: 1.hour) do |req|
    if req.path == '/contacts' && req.post?
      req.ip
    end
  end

  # General request throttling (loose limit)
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Block suspicious requests
  blocklist('block suspicious requests') do |req|
    # Block requests containing suspicious SQL patterns
    CGI.unescape(req.query_string) =~ /(\.|%2e)(\.|%2e)(\/|%2f|\\|%5c)/i ||
    CGI.unescape(req.query_string) =~ /union.*select/i ||
    CGI.unescape(req.query_string) =~ /\b(exec|execute|select|insert|update|delete|drop|create)\b/i
  end

  # Custom responses
  self.throttled_responder = lambda do |req|
    match_data = req.env['rack.attack.match_data']
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{
        error: 'Too Many Requests',
        message: 'リクエスト数が制限を超えました。しばらく待ってから再度お試しください。',
        retry_after: retry_after
      }.to_json]
    ]
  end

  self.blocklisted_responder = lambda do |_req|
    [
      403,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Forbidden', message: 'アクセスが拒否されました。' }.to_json]
    ]
  end
end

# Enable only in production and staging
if Rails.env.production? || Rails.env.staging?
  Rails.application.config.middleware.use Rack::Attack
end