# Session security configuration
Rails.application.config.session_store :cookie_store,
  key: '_portfolio_cms_session',
  secure: Rails.env.production?, # HTTPS only in production
  httponly: true,               # Prevent JavaScript access
  same_site: :lax,             # CSRF protection
  expire_after: 24.hours       # Session expiration