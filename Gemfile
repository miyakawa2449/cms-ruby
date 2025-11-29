source "https://rubygems.org"

ruby "3.4.7"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# 認証・認可
gem "devise", "~> 4.9"                    # ユーザー認証
gem "jwt", "~> 2.7"                       # JWT認証（API用）
gem "pundit", "~> 2.3"                    # 認可（権限管理）

# バックグラウンドジョブ
gem "sidekiq", "~> 7.2"                   # 非同期処理
gem "sidekiq-cron", "~> 1.12"             # 定期ジョブ

# AI・外部API連携
gem "ruby-openai", "~> 6.3"               # OpenAI API (ChatGPT)
gem "httparty", "~> 0.21"                 # HTTPクライアント

# 画像処理・ファイル管理
gem "carrierwave", "~> 3.0"               # ファイルアップロード
gem "mini_magick", "~> 4.12"              # 画像処理
gem "fog-aws", "~> 3.21"                  # AWS S3連携

# SEO・メタデータ
gem "meta-tags", "~> 2.20"                # メタタグ管理
gem "sitemap_generator", "~> 6.3"         # サイトマップ生成
gem "friendly_id", "~> 5.5"               # SEOフレンドリーURL

# 検索・全文検索
gem "pg_search", "~> 2.3"                 # PostgreSQL全文検索

# セキュリティ
gem "rack-attack", "~> 6.7"               # レート制限・DDoS対策
gem "rack-cors", "~> 2.0"                 # CORS設定（API用）
gem "brakeman", "~> 6.1", require: false  # セキュリティ脆弱性チェック

# パフォーマンス・キャッシュ
# gem "redis-rails", "~> 5.0"              # Rails 8.0対応待ち
gem "dalli", "~> 3.2"                     # Memcachedクライアント（オプション）

# API開発
gem "active_model_serializers", "~> 0.10.14"  # APIシリアライザ
gem "kaminari", "~> 1.2"                  # ページネーション
gem "api-pagination", "~> 5.0"            # APIページネーション

# Markdown・コンテンツ処理
gem "redcarpet", "~> 3.6"                 # Markdownパーサー
gem "rouge", "~> 4.2"                     # シンタックスハイライト

# 監視・ログ
gem "lograge", "~> 0.14"                  # ログフォーマット最適化
gem "sentry-rails", "~> 5.15"             # エラー監視
gem "sentry-sidekiq", "~> 5.15"           # Sidekiqエラー監視

# その他ユーティリティ
gem "dotenv-rails", "~> 2.8"              # 環境変数管理
gem "whenever", "~> 1.0", require: false  # cron管理
gem "geocoder", "~> 1.8"                  # ジオコーディング（アクセス解析用）
gem "browser", "~> 5.3"                   # ユーザーエージェント解析

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # RSpec
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  
  # 静的コード解析
  gem "rubocop", "~> 1.60", require: false
  gem "rubocop-rails", "~> 2.23", require: false
  gem "rubocop-rspec", "~> 2.26", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # デバッグ・開発効率化
  gem "better_errors", "~> 2.10"
  gem "binding_of_caller", "~> 1.0"
  gem "annot8"                           # Rails 8.0対応アノテーションgem
  gem "bullet", "~> 7.1"                # N+1クエリ検出
  gem "letter_opener", "~> 1.8"         # 開発環境でメール確認
  gem "rails-erd", "~> 1.7"             # ER図生成
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  
  # テストカバレッジ
  gem "simplecov", "~> 0.22", require: false
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "webmock", "~> 3.19"              # 外部API呼び出しのモック
  gem "vcr", "~> 6.2"                   # HTTPインタラクション記録
end