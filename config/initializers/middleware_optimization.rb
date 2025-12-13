# Rails 8.0.4 Middleware Stack Optimization
# Web request DB connection issues workaround

Rails.application.configure do
  # Disable migration check for web requests (keep for console)
  if Rails.env.development?
    # Only disable for web requests, not console/runner
    config.middleware.delete(ActiveRecord::Migration::CheckPending) if defined?(Puma)
  end
  
  # Connection pool optimization
  config.after_initialize do
    ActiveRecord::Base.connection_pool.disconnect!
    ActiveRecord::Base.establish_connection
  end
end