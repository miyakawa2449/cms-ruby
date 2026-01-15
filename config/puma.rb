# Puma configuration for Rails 8.0.4
# Optimized for stability and compatibility

# Threads configuration
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Port configuration
port ENV.fetch("PORT") { 3000 }

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# Development-specific optimizations
if ENV["RAILS_ENV"] == "development"
  # Single mode for development to avoid connection issues
  workers 0

  # Disable preload for development stability
  preload_app! false

  # Connection optimization for single mode (not worker mode)
  before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord::Base)
  end
end

# Production configuration
if ENV["RAILS_ENV"] == "production"
  # Use multiple workers in production
  workers ENV.fetch("WEB_CONCURRENCY") { 2 }

  # Preload application for memory efficiency
  preload_app!

  # Solid Queue integration for production
  plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

  # PID file for production
  pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
end

# Allow puma to be restarted by rails restart
plugin :tmp_restart
