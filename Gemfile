source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Authentication & Authorization
gem "devise", "~> 4.9"
gem "jwt", "~> 3.1"
gem "pundit", "~> 2.3"

# Background Processing
gem "sidekiq", "~> 8.0"
gem "sidekiq-cron", "~> 2.3"

# Caching & Redis
gem "redis", ">= 4.0.1"

# AI & External APIs
gem "ruby-openai", "~> 8.3"
gem "httparty", "~> 0.21"

# SEO & Performance
gem "meta-tags", "~> 2.19"
gem "friendly_id", "~> 5.5"
gem "kaminari", "~> 1.2"

# Search & Indexing
gem "pg_search", "~> 2.3"

# Security & Monitoring
gem "rack-attack", "~> 6.6"
gem "sentry-rails", "~> 5.15"
gem "sentry-sidekiq", "~> 5.15"

# CSS Framework & Assets
gem "tailwindcss-rails", "~> 3.0"
gem "cssbundling-rails", "~> 1.4"
gem "jsbundling-rails", "~> 1.3"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Markdown processing
gem "redcarpet", "~> 3.6"

# ZIP file handling
gem "rubyzip", "~> 2.3"

# AWS Services
gem "aws-sdk-sesv2", "~> 1.35"         # SES for email delivery
gem "aws-sdk-rails", "~> 4.0"          # Rails integration
gem "aws-sdk-bedrockruntime", "~> 1.0" # Bedrock for AI features

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing Framework
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "webmock", "~> 3.19"
  gem "vcr", "~> 6.2"
  gem "simplecov", "~> 0.22"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Claude Code MCP Server for Rails
  gem "claude-on-rails"

  # Development & Debugging Tools
  gem "better_errors", "~> 2.10"
  gem "binding_of_caller", "~> 1.0"
  gem "letter_opener", "~> 1.10"
  gem "listen", "~> 3.8"
  gem "spring", "~> 4.1"
  gem "spring-commands-rspec", "~> 1.0"
  gem "dotenv-rails", "~> 2.8"

  # Performance Monitoring & Optimization
  gem "bullet", "~> 8.0"                   # N+1 query detection
  gem "rack-mini-profiler", "~> 3.3"       # Page load profiling
  gem "memory_profiler", "~> 1.0"          # Memory profiling
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "rails-controller-testing"
end
