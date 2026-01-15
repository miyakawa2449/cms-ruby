# Puma configuration for Rails 8.1.1
# Optimized for development environment

# Threads configuration
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Port configuration
port ENV.fetch("PORT") { 3000 }

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# Restart capability
plugin :tmp_restart

# Development-specific optimizations
if ENV["RAILS_ENV"] == "development"
  # Single mode for development to avoid connection issues
  workers 0

  # Preload application for faster startup in development
  preload_app! false

  # Enable reloading
  plugin :tmp_restart
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
