# Database Connection Health Check for Rails 8.0.4
# Ensures proper DB connection on application startup

Rails.application.configure do
  config.after_initialize do
    # Only run in development for web requests
    if Rails.env.development? && defined?(Puma)
      begin
        # Test database connection
        ActiveRecord::Base.connection.execute("SELECT 1")
        Rails.logger.info "✅ Database connection verified"
      rescue => e
        Rails.logger.error "❌ Database connection failed: #{e.message}"
        # Attempt to reestablish connection
        ActiveRecord::Base.establish_connection
        Rails.logger.info "🔄 Attempting to reestablish database connection"
      end
    end
  end
end