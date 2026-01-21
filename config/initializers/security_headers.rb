# frozen_string_literal: true

Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Content-Type-Options" => "nosniff",
  "X-XSS-Protection" => "1; mode=block",
  "X-Frame-Options" => "SAMEORIGIN",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "geolocation=(), microphone=(), camera=()"
)

if Rails.env.production? && ENV.fetch("ENABLE_HSTS", "true") == "true"
  Rails.application.config.ssl_options ||= {}
  Rails.application.config.ssl_options[:hsts] = {
    expires: ENV.fetch("HSTS_MAX_AGE", 31_536_000).to_i,
    subdomains: true,
    preload: true
  }
end
