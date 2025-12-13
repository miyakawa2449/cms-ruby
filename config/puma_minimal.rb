# Minimal Puma configuration for Rails 8.0.4 troubleshooting
# Eliminates all potential configuration issues

# Basic thread configuration
threads 1, 1

# Port configuration
port ENV.fetch("PORT") { 3000 }

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# Minimal single mode (no workers, no preload)
workers 0

# Allow restart
plugin :tmp_restart

# No additional configuration - pure Rails 8.0.4 defaults