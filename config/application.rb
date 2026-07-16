require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PortfolioRb
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks middleware])

    # 管理画面パス変更を再起動なしで全プロセスに反映する（監査C-10）
    require_relative "../lib/middleware/admin_path_route_reloader"
    config.middleware.use AdminPathRouteReloader

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Asia/Tokyo"

    # Locale settings
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [ :ja, :en ]

    # Security headers
    config.action_dispatch.default_headers = {
      "X-Frame-Options" => "SAMEORIGIN",
      "X-XSS-Protection" => "0", # Deprecated but kept for compatibility
      "X-Content-Type-Options" => "nosniff",
      "X-Download-Options" => "noopen",
      "X-Permitted-Cross-Domain-Policies" => "none",
      "Referrer-Policy" => "strict-origin-when-cross-origin"
    }

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
