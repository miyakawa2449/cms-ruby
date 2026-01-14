# Web接続問題解決テスト・完全レポート

**📅 実施日**: 2025年12月12日  
**🎯 目的**: Rails console正常・Webリクエスト500エラー問題の根本解決  
**⚡ 環境**: Rails 8.0.4 + PostgreSQL 16-alpine + Docker環境

---

## 🔍 問題の症状

### ✅ 正常動作
- **Rails Console/Runner**: `docker-compose run --rm web rails runner "puts 'SUCCESS'"`
- **データベース接続**: `ActiveRecord::Base.connection.execute('SELECT version()')`
- **マイグレーション**: `rails db:migrate` 正常実行
- **シード**: `rails db:seed` 正常実行

### ❌ 異常動作  
- **Webリクエスト**: `curl http://localhost:3000/test` → 500エラー
- **エラー内容**: `ActiveRecord::DatabaseConnectionError at /test - There is an issue connecting with your hostname: db`
- **管理画面**: `http://localhost:3000/admin` → 同様の500エラー

---

## 🧪 実施したテスト・解決案

### 案1: Middleware Stack最適化
**ファイル**: `/config/initializers/middleware_optimization.rb`
```ruby
# Migration check middleware削除・Connection pool最適化
Rails.application.configure do
  config.middleware.delete(ActiveRecord::Migration::CheckPending) if defined?(Puma)
  config.after_initialize do
    ActiveRecord::Base.connection_pool.disconnect!
    ActiveRecord::Base.establish_connection
  end
end
```
**結果**: ❌ 500エラー継続

### 案2: Connection Pool設定最適化  
**ファイル**: `/config/database.yml`
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  # Connection pool optimization for Rails 8.0.4
  checkout_timeout: 5
  reaping_frequency: 10
  idle_timeout: 300
```
**結果**: ❌ 500エラー継続

### 案3: Puma設定詳細最適化
**ファイル**: `/config/puma.rb`
```ruby
# Single mode専用設定・deprecation警告対応
if ENV["RAILS_ENV"] == "development"
  workers 0
  preload_app! false
  before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord::Base)
  end
end
```
**結果**: ❌ 500エラー継続（警告は解決）

### 案4: 環境変数による接続強制
**ファイル**: `/config/database.yml`
```yaml
development:
  <<: *default
  url: <%= ENV['DATABASE_URL'] || "postgresql://portfolio:portfolio_password@db:5432/portfolio_rb_development" %>
  database: portfolio_rb_development
  username: portfolio
  password: portfolio_password
  host: db
  port: 5432
```
**結果**: ❌ 500エラー継続

### 案5: Application初期化時DB接続確認
**ファイル**: `/config/initializers/database_connection_check.rb`
```ruby
# 起動時DB接続テスト・自動再接続機能
Rails.application.configure do
  config.after_initialize do
    if Rails.env.development? && defined?(Puma)
      begin
        ActiveRecord::Base.connection.execute("SELECT 1")
        Rails.logger.info "✅ Database connection verified"
      rescue => e
        ActiveRecord::Base.establish_connection
      end
    end
  end
end
```
**結果**: ❌ 500エラー継続

### 案6: Docker Network診断
**ファイル**: `/config/initializers/docker_network_diagnostic.rb`
```ruby
# コンテナ間通信確認・DNS/TCP接続テスト
require 'socket'
db_ip = Socket.getaddrinfo('db', nil).first[2]
socket = TCPSocket.new('db', 5432)
```
**結果**: ✅ ネットワーク正常・❌ Web500エラー継続

### 案7: Puma Single Mode最適化
- Deprecation警告解決（`on_worker_boot` → `before_fork`）
- Single mode専用フック使用
**結果**: ❌ 500エラー継続

### 案8: 最小構成テスト
**ファイル**: `/config/puma_minimal.rb`
```ruby
# 最小構成・純粋Rails 8.0.4デフォルト
threads 1, 1
port ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }
workers 0
plugin :tmp_restart
```
**結果**: ❌ 500エラー継続

---

## 📊 検証結果・技術分析

### 🔍 判明事項
1. **Rails Console/Runner正常**: DB接続・ActiveRecord動作に問題なし
2. **Docker環境正常**: PostgreSQL 16-alpine・Redis 7-alpine稼働
3. **Network正常**: コンテナ間通信・DNS解決・TCP接続確認済み
4. **設定正常**: database.yml・環境変数・接続パラメータ確認済み

### 🤔 推定原因
1. **Rails 8.0.4 Webリクエスト処理固有の問題**
2. **Middleware stack中のDB接続タイミング問題**
3. **Puma + ActiveRecord間の接続プール同期問題**
4. **Rails 8系全般のDocker環境互換性問題**

### 📝 エラーパターン分析
- **一貫性**: 全Webリクエストで同一エラー
- **再現性**: 環境再構築後も100%再現
- **限定性**: Console/Runnerは完全正常動作
- **タイミング**: Web初回リクエスト時にDB接続失敗

---

## 🎯 明日の検証計画

### 📋 シンプルテスト設計
**目的**: 根本的な動作確認・問題箇所の特定

#### 1. 最小DBテストテーブル作成
```ruby
# マイグレーション: CreateTestItems
class CreateTestItems < ActiveRecord::Migration[8.0]
  def change
    create_table :test_items do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
  end
end
```

#### 2. シンプルモデル作成
```ruby
# app/models/test_item.rb
class TestItem < ApplicationRecord
  validates :name, presence: true
end
```

#### 3. 専用コントローラー作成
```ruby
# app/controllers/test_controller.rb
class TestController < ApplicationController
  def index
    @test_items = TestItem.all
    render plain: "Test Items Count: #{@test_items.count}\nItems: #{@test_items.map(&:name).join(', ')}"
  rescue => e
    render plain: "Error: #{e.class}: #{e.message}"
  end
end
```

#### 4. ルート追加
```ruby
# config/routes.rb
get "test", to: "test#index"
```

#### 5. テストデータ投入
```ruby
# rails console
TestItem.create!(name: "Sample 1", description: "Test data 1")
TestItem.create!(name: "Sample 2", description: "Test data 2")
```

### 🎯 検証目標
1. **基本動作**: `http://localhost:3000/test` でDB値表示
2. **エラー特定**: 具体的なエラー箇所・タイミング特定
3. **解決策発見**: 最小構成での動作確認後、段階的機能追加

---

## 📁 今日の実装ファイル

### 新規作成ファイル
- `/config/initializers/middleware_optimization.rb`
- `/config/initializers/database_connection_check.rb`  
- `/config/initializers/docker_network_diagnostic.rb`
- `/config/puma_minimal.rb`

### 修正ファイル
- `/config/database.yml` - Connection pool最適化
- `/config/puma.rb` - Single mode最適化
- 各種ドキュメント更新（README.md, spec.md, phase_plan等）

---

## 💭 所感・次回方針

### 🤔 技術判断
- **ダウングレード**: Rails 7.2系は極端すぎる判断に同意
- **根本原因**: 設定ではなく、Rails 8系固有の問題の可能性
- **アプローチ**: 複雑な機能を排除し、最小構成でのテスト実施が適切

### 🎯 明日の目標
1. **シンプルテスト**: 最小DB・最小コントローラーでの動作確認
2. **段階的検証**: 動作する最小構成から機能を段階的追加
3. **問題特定**: 具体的にどの機能・設定が問題を引き起こすかを特定

---

**🚀 継続セッション準備完了**: 明日は根本的な動作確認から開始し、問題の本質を特定します。