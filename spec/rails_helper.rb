# Rails RSpec Configuration for Portfolio Site
# Phase 2A: 基本設定ファイル準備（Phase 2BでBundle installした後に有効化）

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Add additional requires below this line. Rails is not loaded until this point!
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # ==> Custom Configuration for Portfolio Site
  
  # Configure test database cleaner (Phase 2Bで有効化予定)
  # config.before(:suite) do
  #   DatabaseCleaner.strategy = :transaction
  #   DatabaseCleaner.clean_with(:truncation)
  # end
  
  # config.around(:each) do |example|
  #   DatabaseCleaner.cleaning do
  #     example.run
  #   end
  # end
  
  # Include test helpers
  config.include Rails.application.routes.url_helpers
  # config.include FactoryBot::Syntax::Methods
  config.include ActionDispatch::TestProcess::FixtureFile
  
  # Configure Devise test helpers (Phase 2Bで有効化予定)
  # config.include Devise::Test::ControllerHelpers, type: :controller
  # config.include Devise::Test::IntegrationHelpers, type: :request
  # config.include Devise::Test::IntegrationHelpers, type: :system
  
  # Custom helpers
  config.include AdminTestHelpers, type: :controller
  config.include AdminTestHelpers, type: :request
  config.include ApiTestHelpers, type: :request
  config.include FileTestHelpers
  
  # Configure system tests (Phase 2Bで有効化予定)
  # config.before(:each, type: :system) do
  #   driven_by :selenium_chrome_headless
  # end
  
  # Configure feature tests with Capybara (Phase 2Bで有効化予定)
  # Capybara.configure do |capybara_config|
  #   capybara_config.default_max_wait_time = 5
  #   capybara_config.default_driver = :selenium_chrome_headless
  # end
  
  # Configure test environment settings
  config.before(:each) do
    # Reset ActionMailer deliveries
    ActionMailer::Base.deliveries.clear
    
    # Set consistent timezone
    Time.zone = 'Asia/Tokyo'
    
    # Clear Rails cache
    Rails.cache.clear
    
    # Reset any global state
    # Current.user = nil if defined?(Current)
  end
  
  # Configure specific test types
  config.before(:each, type: :request) do
    host! 'localhost:3000'
  end
  
  config.before(:each, type: :controller) do
    @routes = Rails.application.routes
  end
  
  # Configure test tags
  config.filter_run_excluding :slow unless ENV['SLOW_TESTS']
  config.filter_run_excluding :integration unless ENV['INTEGRATION_TESTS']
  config.filter_run_excluding :system unless ENV['SYSTEM_TESTS']
  
  # Configure shared examples
  config.shared_context_metadata_behavior = :apply_to_host_groups
  
  # Configure custom expectations
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  
  # Configure mocking
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

# ==> Test Environment Configuration

# Configure Rails test environment
Rails.application.configure do
  # Test-specific configuration
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test
  config.active_support.deprecation = :stderr
end

# Configure logging for tests
Rails.logger.level = Logger::ERROR unless ENV['VERBOSE_TESTS']

# Configure Active Job for tests
ActiveJob::Base.queue_adapter = :test