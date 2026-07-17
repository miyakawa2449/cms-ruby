require "capybara/rspec"
require "selenium-webdriver"
require "tmpdir"
require "warden/test/helpers"

Capybara.register_driver :selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  chrome_bin = ENV["CHROME_BIN"]
  if chrome_bin && !chrome_bin.empty?
    options.binary = chrome_bin
  else
    %w[/snap/bin/chromium /usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome].each do |path|
      next unless File.exist?(path)

      options.binary = path
      break
    end
  end
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-setuid-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--disable-extensions")
  options.add_argument("--disable-software-rasterizer")
  options.add_argument("--no-zygote")
  options.add_argument("--no-first-run")
  options.add_argument("--no-default-browser-check")
  options.add_argument("--enable-logging")
  options.add_argument("--v=1")
  options.add_argument("--log-file=#{Rails.root.join('tmp/chrome.log')}")
  options.add_argument("--user-data-dir=#{Dir.mktmpdir('chrome-profile')}")
  options.add_argument("--remote-debugging-port=9222")
  options.add_argument("--window-size=1920,1080")

  service = nil
  driver_path = ENV["CHROMEDRIVER_PATH"]
  if driver_path && !driver_path.empty?
    service = Selenium::WebDriver::Chrome::Service.new(
      path: driver_path,
      args: ["--verbose", "--log-path=tmp/chromedriver.log"]
    )
  else
    %w[/usr/lib/chromium-browser/chromedriver /usr/bin/chromedriver /snap/bin/chromedriver].each do |path|
      next unless File.exist?(path)

      service = Selenium::WebDriver::Chrome::Service.new(
        path: path,
        args: ["--verbose", "--log-path=tmp/chromedriver.log"]
      )
      break
    end
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_headless
Capybara.default_max_wait_time = 5
Capybara.save_path = Rails.root.join("tmp/capybara")

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :system

  config.before(:each, type: :system) do
    Warden.test_mode!
    # 旧: Blob#image?を全system specでfalseにスタブしていたが、
    # メディア系E2Eの検証価値を失うためS1-7 P5-3で撤去（libvips導入済みで実解析可能）
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
