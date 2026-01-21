# 開発環境＆デプロイメント仕様書

## 開発環境構成

### システム要件
- **OS**: macOS Monterey 12.0以上 / Ubuntu 20.04以上
- **Docker**: 20.10以上
- **Docker Compose**: 2.0以上
- **Git**: 2.30以上

### 技術スタック
- **Ruby**: 3.4.7
- **Rails**: 8.1.1
- **PostgreSQL**: 17-alpine
- **Redis**: 7-alpine
- **Node.js**: 20.x（Dockerコンテナ内）

## Docker環境

### docker-compose.yml
```yaml
version: '3.8'

services:
  # メインアプリケーション
  web:
    build: 
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=postgresql://portfolio:portfolio_password@db:5432/portfolio_rb_development
      - REDIS_URL=redis://redis:6379/0
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
      - node_modules:/app/node_modules
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    stdin_open: true
    tty: true
    networks:
      - portfolio_network

  # PostgreSQL データベース
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: portfolio_rb_development
      POSTGRES_USER: portfolio
      POSTGRES_PASSWORD: portfolio_password
      POSTGRES_INITDB_ARGS: "--locale-provider=icu --icu-locale=ja-JP"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./db/init:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U portfolio"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - portfolio_network

  # Redis（セッション・キャッシュ・ジョブキュー）
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - portfolio_network

  # Sidekiq（バックグラウンドジョブ）
  sidekiq:
    build: 
      context: .
      dockerfile: Dockerfile.dev
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=postgresql://portfolio:portfolio_password@db:5432/portfolio_rb_development
      - REDIS_URL=redis://redis:6379/0
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    depends_on:
      - db
      - redis
      - web
    command: bundle exec sidekiq
    networks:
      - portfolio_network

volumes:
  postgres_data:
  redis_data:
  bundle_cache:
  node_modules:

networks:
  portfolio_network:
    driver: bridge
```

### Dockerfile.dev
```dockerfile
FROM ruby:3.4.7-alpine

# システム依存関係のインストール
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    nodejs \
    npm \
    yarn \
    git \
    imagemagick \
    vips-dev

# 作業ディレクトリ設定
WORKDIR /app

# Bundler設定
ENV BUNDLE_PATH=/usr/local/bundle
ENV BUNDLE_BIN=/usr/local/bundle/bin
ENV GEM_HOME=/usr/local/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

# Gemfileのコピーと依存関係インストール
COPY Gemfile Gemfile.lock ./
RUN bundle install

# package.jsonのコピーとNode.js依存関係インストール
COPY package.json yarn.lock ./
RUN yarn install

# アプリケーションコードのコピー
COPY . .

# ポート設定
EXPOSE 3000

# 開発サーバー起動
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### 開発環境セットアップ

#### 初回セットアップ
```bash
# リポジトリクローン
git clone https://github.com/user/portfolio_rb.git
cd portfolio_rb

# 環境変数ファイル作成
cp .env.example .env

# Rails Master Key設定
echo "your_master_key_here" > config/master.key

# Docker環境構築
docker-compose build
docker-compose up -d

# データベース初期化
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
docker-compose exec web rails db:seed

# アセット構築
docker-compose exec web rails assets:precompile
```

#### 日常的な開発コマンド
```bash
# 開発環境起動
docker-compose up

# バックグラウンド実行
docker-compose up -d

# ログ確認
docker-compose logs -f web

# Railsコンソール
docker-compose exec web rails console

# テスト実行
docker-compose exec web rails test

# データベースリセット
docker-compose exec web rails db:reset

# 依存関係更新
docker-compose exec web bundle install
docker-compose exec web yarn install

# 環境停止・クリーンアップ
docker-compose down
docker-compose down -v  # ボリュームも削除
```

## データベース管理

### マイグレーション管理
```bash
# マイグレーション作成
docker-compose exec web rails generate migration CreateNewTable

# マイグレーション実行
docker-compose exec web rails db:migrate

# ロールバック
docker-compose exec web rails db:rollback STEP=1

# マイグレーションステータス確認
docker-compose exec web rails db:migrate:status

# スキーマダンプ
docker-compose exec web rails db:schema:dump
```

### シードデータ
```ruby
# db/seeds.rb
puts "🌱 シードデータを作成中..."

# 管理者ユーザー作成
admin_user = AdminUser.find_or_create_by(email: 'admin@example.com') do |user|
  user.password = 'SecurePassword123!'
  user.password_confirmation = 'SecurePassword123!'
  user.name = '管理者'
  user.confirmed_at = Time.current
end

puts "✅ 管理者ユーザー作成: #{admin_user.email}"

# デフォルトセクション作成
Section.seed_defaults
puts "✅ デフォルトセクション作成"

# サンプルカテゴリ作成
programming = Category.find_or_create_by(name: 'プログラミング') do |category|
  category.slug = 'programming'
  category.description = 'プログラミング技術に関する記事'
  category.color = '#3b82f6'
  category.icon = 'code'
  category.position = 1
end

rails_category = Category.find_or_create_by(name: 'Ruby on Rails', parent: programming) do |category|
  category.slug = 'ruby-on-rails'
  category.description = 'Rails関連の記事'
  category.color = '#cc0000'
  category.position = 1
end

works_category = Category.find_or_create_by(name: 'Works') do |category|
  category.slug = 'works'
  category.description = '実績・ポートフォリオ作品'
  category.color = '#10b981'
  category.icon = 'briefcase'
  category.position = 99
end

puts "✅ カテゴリ作成完了"

# サンプル記事作成
sample_article = Article.find_or_create_by(slug: 'welcome-to-portfolio') do |article|
  article.admin_user = admin_user
  article.title = 'ポートフォリオサイトへようこそ'
  article.content = <<~CONTENT
    # ポートフォリオサイトへようこそ

    このサイトは Ruby on Rails 8.1.1 で構築された
    シニアエンジニアのポートフォリオ・技術ブログサイトです。

    ## 特徴

    - Rails 8.1.1の最新機能を活用
    - レスポンシブデザイン（Tailwind CSS）
    - CMS機能完備
    - API対応

    今後とも宜しくお願いいたします。
  CONTENT
  article.excerpt = 'ポートフォリオサイトの紹介記事です。'
  article.status = 'published'
  article.published_at = Time.current
end

sample_article.categories = [programming]

puts "✅ サンプル記事作成: #{sample_article.title}"

puts "🎉 シードデータ作成完了!"
```

## テスト環境

### テスト設定
```ruby
# config/environments/test.rb
Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  
  # テスト用データベース
  config.active_storage.service = :test
  
  # メール設定
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_caching = false
  
  # ログレベル
  config.log_level = :warn
  config.active_support.deprecation = :stderr
  
  # 高速化設定
  config.active_support.test_order = :random
end
```

### RSpec設定
```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Database Cleaner設定
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
  
  # Factory Bot
  config.include FactoryBot::Syntax::Methods
  
  # Devise test helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
end
```

### Factory Bot設定
```ruby
# spec/factories/admin_users.rb
FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { 'SecurePassword123!' }
    name { 'テスト管理者' }
    confirmed_at { Time.current }
  end
end

# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    association :admin_user
    sequence(:title) { |n| "テスト記事 #{n}" }
    sequence(:slug) { |n| "test-article-#{n}" }
    content { "# テスト記事\n\nテスト用のコンテンツです。" }
    excerpt { "テスト記事の抜粋です。" }
    status { 'published' }
    published_at { Time.current }
    
    trait :draft do
      status { 'draft' }
      published_at { nil }
    end
    
    trait :with_categories do
      after(:create) do |article|
        article.categories << create(:category)
      end
    end
  end
end
```

### テスト実行
```bash
# 全テスト実行
docker-compose exec web rspec

# 特定のテストファイル実行
docker-compose exec web rspec spec/models/article_spec.rb

# 特定のテストケース実行
docker-compose exec web rspec spec/models/article_spec.rb:10

# カバレッジ確認
docker-compose exec web rspec --format documentation
```

## 本番環境（AWS Lightsail）

### インフラ構成
```
┌─────────────────┐    ┌─────────────────┐
│   CloudFlare    │    │   Route 53      │
│   (CDN/WAF)     │ -> │   (DNS)         │
└─────────────────┘    └─────────────────┘
          |                      |
          v                      v
┌─────────────────────────────────────────┐
│           Load Balancer                 │
│        (Nginx/SSL Termination)         │
└─────────────────────────────────────────┘
                    |
                    v
┌─────────────────────────────────────────┐
│          Application Servers           │
│    Lightsail Instance (2GB RAM)        │
│    - Rails App (Puma)                  │
│    - Sidekiq Workers                    │
│    - PostgreSQL                        │
│    - Redis                             │
└─────────────────────────────────────────┘
                    |
                    v
┌─────────────────────────────────────────┐
│              Storage                    │
│    - Static files (Lightsail)          │
│    - Database backups (S3)             │
│    - Application logs (CloudWatch)     │
└─────────────────────────────────────────┘
```

### Lightsail設定

#### インスタンス仕様
- **プラン**: 2GB RAM / 1 vCPU / 60GB SSD
- **OS**: Ubuntu 22.04 LTS
- **IPv4**: 静的IP割り当て
- **ファイアウォール**: HTTP(80), HTTPS(443), SSH(22)

#### 初期セットアップスクリプト
```bash
#!/bin/bash
# setup_lightsail.sh

set -e

echo "🚀 AWS Lightsail セットアップ開始..."

# システム更新
sudo apt update && sudo apt upgrade -y

# 必要パッケージインストール
sudo apt install -y \
  curl wget git unzip \
  build-essential libssl-dev \
  postgresql postgresql-contrib \
  redis-server nginx certbot \
  python3-certbot-nginx

# Ruby インストール（rbenv使用）
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

rbenv install 3.4.7
rbenv global 3.4.7

# Node.js インストール
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Yarn インストール
npm install -g yarn

# PostgreSQL セットアップ
sudo -u postgres createuser -s portfolio
sudo -u postgres createdb portfolio_production
sudo -u postgres psql -c "ALTER USER portfolio PASSWORD 'SECURE_PASSWORD';"

# Redis セットアップ
sudo systemctl enable redis-server
sudo systemctl start redis-server

echo "✅ Lightsail セットアップ完了"
```

### デプロイ設定

#### Capistrano設定
```ruby
# config/deploy.rb
lock "~> 3.18.0"

set :application, "portfolio_rb"
set :repo_url, "https://github.com/user/portfolio_rb.git"
set :branch, ENV['BRANCH'] || 'main'

# デプロイ先設定
set :deploy_to, "/var/www/portfolio"
set :user, "deploy"

# Rails設定
set :rails_env, "production"
set :assets_roles, [:web, :app]
set :migration_role, [:db]

# Bundler設定
set :bundle_path, -> { "#{shared_path}/bundle" }
set :bundle_flags, '--quiet --no-cache'
set :bundle_without, %w{development test}.join(' ')

# 共有ファイル
append :linked_files, 
  "config/master.key",
  "config/database.yml",
  ".env.production"

append :linked_dirs, 
  "log", 
  "tmp/pids", 
  "tmp/cache", 
  "tmp/sockets", 
  "public/system",
  "storage"

# タスク設定
namespace :deploy do
  after :publishing, :restart
  after :finishing, :cleanup
  
  desc 'Restart application'
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :puma
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end
end
```

#### 環境別設定
```ruby
# config/deploy/production.rb
server "your-lightsail-ip", 
  user: "deploy",
  roles: %w{app db web},
  ssh_options: {
    keys: %w(~/.ssh/lightsail_key.pem),
    forward_agent: false,
    auth_methods: %w(publickey)
  }

set :rails_env, "production"
set :puma_conf, "#{shared_path}/config/puma.rb"
```

### Systemd サービス

#### Puma サービス
```ini
# /etc/systemd/system/puma.service
[Unit]
Description=Puma Rails Server
After=network.target

[Service]
Type=notify
User=deploy
Group=deploy
WorkingDirectory=/var/www/portfolio/current
Environment=RAILS_ENV=production
Environment=PUMA_PIDFILE=/var/www/portfolio/shared/tmp/pids/puma.pid
Environment=PUMA_CONFIG_FILE=/var/www/portfolio/shared/config/puma.rb
ExecStart=/home/deploy/.rbenv/shims/bundle exec puma -C /var/www/portfolio/shared/config/puma.rb
ExecReload=/bin/kill -USR1 $MAINPID
TimeoutStopSec=60
Restart=always

[Install]
WantedBy=multi-user.target
```

#### Sidekiq サービス
```ini
# /etc/systemd/system/sidekiq.service
[Unit]
Description=Sidekiq Background Workers
After=network.target

[Service]
Type=notify
User=deploy
Group=deploy
WorkingDirectory=/var/www/portfolio/current
Environment=RAILS_ENV=production
ExecStart=/home/deploy/.rbenv/shims/bundle exec sidekiq -e production
ExecReload=/bin/kill -USR1 $MAINPID
TimeoutStopSec=60
Restart=always

[Install]
WantedBy=multi-user.target
```

### Nginx設定
```nginx
# /etc/nginx/sites-available/portfolio
upstream puma {
  server unix:///var/www/portfolio/shared/tmp/sockets/puma.sock;
}

server {
  listen 80;
  server_name example.test www.example.test;
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl http2;
  server_name example.test www.example.test;

  root /var/www/portfolio/current/public;
  access_log /var/log/nginx/portfolio_access.log;
  error_log /var/log/nginx/portfolio_error.log;

  # SSL設定
  ssl_certificate /etc/letsencrypt/live/example.test/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/example.test/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
  ssl_prefer_server_ciphers off;

  # セキュリティヘッダー
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
  add_header X-XSS-Protection "1; mode=block";
  add_header Referrer-Policy "strict-origin-when-cross-origin";

  # 静的ファイル
  location ^~ /assets/ {
    gzip_static on;
    expires 1y;
    add_header Cache-Control public;
    add_header Last-Modified "";
    add_header ETag "";
    break;
  }

  # Railsアプリケーション
  try_files $uri/index.html $uri @puma;

  location @puma {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;

    proxy_pass http://puma;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 10M;
  keepalive_timeout 10;
}
```

### SSL証明書設定
```bash
# Let's Encrypt証明書取得
sudo certbot --nginx -d example.test -d www.example.test

# 自動更新設定
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

### モニタリング・ログ

#### アプリケーション監視
```ruby
# config/initializers/health_check.rb
class HealthCheck
  def self.status
    {
      status: 'OK',
      timestamp: Time.current.iso8601,
      version: ENV['APP_VERSION'],
      services: {
        database: database_status,
        redis: redis_status,
        storage: storage_status
      }
    }
  end

  private

  def self.database_status
    ActiveRecord::Base.connection.active? ? 'OK' : 'ERROR'
  rescue
    'ERROR'
  end

  def self.redis_status
    Redis.new.ping == 'PONG' ? 'OK' : 'ERROR'
  rescue
    'ERROR'
  end

  def self.storage_status
    ActiveStorage::Blob.service.exist?('health_check') ? 'OK' : 'UNKNOWN'
  rescue
    'UNKNOWN'
  end
end
```

#### ログローテーション
```bash
# /etc/logrotate.d/portfolio
/var/www/portfolio/shared/log/*.log {
  daily
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  create 0644 deploy deploy
  postrotate
    if [ -f /var/run/nginx.pid ]; then
      nginx -s reload > /dev/null 2>&1 || true
    fi
    systemctl reload puma || true
  endscript
}
```

### バックアップ

#### データベースバックアップ
```bash
#!/bin/bash
# scripts/backup_db.sh

set -e

BACKUP_DIR="/var/backups/portfolio"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="portfolio_production"

mkdir -p $BACKUP_DIR

# PostgreSQL バックアップ
pg_dump $DB_NAME | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# 古いバックアップ削除（30日以上）
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +30 -delete

echo "✅ Database backup completed: $BACKUP_DIR/db_backup_$DATE.sql.gz"
```

#### 自動バックアップ設定
```bash
# crontab設定
0 2 * * * /var/www/portfolio/scripts/backup_db.sh >> /var/log/backup.log 2>&1
```