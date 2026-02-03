require "capybara/rspec"
require "selenium-webdriver"
require "warden/test/helpers"

Capybara.register_driver :selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"]&.length&.positive?
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1920,1080")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_headless
Capybara.default_max_wait_time = 5
Capybara.save_path = Rails.root.join("tmp/capybara")

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :system

  config.before(:each, type: :system) do
    Warden.test_mode!
    allow_any_instance_of(ActiveStorage::Blob).to receive(:image?).and_return(false)
  end

  config.after(:each, type: :system) do |example|
    next unless example.exception

    filename = "#{example.full_description.parameterize}.png"
    save_screenshot(File.join(Capybara.save_path, filename))
  end

  config.after(:each, type: :system) do
    Warden.test_reset!
  end
end
