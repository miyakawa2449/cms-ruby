# Phase 5.6: パフォーマンス最適化 - 設計書

**Phase**: 5.6  
**機能名**: パフォーマンス最適化  
**作成日**: 2026-01-18  
**作成者**: Kiro

---

## 📋 目次

1. [アーキテクチャ設計](#アーキテクチャ設計)
2. [N+1問題の解消](#n1問題の解消)
3. [Redisキャッシュ設計](#redisキャッシュ設計)
4. [アセット最適化](#アセット最適化)
5. [パフォーマンス測定](#パフォーマンス測定)
6. [テスト仕様](#テスト仕様)

---

## 🏗️ アーキテクチャ設計

### システム構成図

```
┌─────────────────────────────────────────────────────────┐
│                    ブラウザ                              │
│  - Lazy Loading（画像遅延読み込み）                      │
│  - 圧縮されたCSS/JS                                      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Railsアプリケーション                  │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │ コントローラー    │  │ ビュー（フラグメントキャッシュ）│ │
│  │ - クエリ最適化    │  │ - サイドバーキャッシュ    │    │
│  │ - includes/preload│  │ - 記事一覧キャッシュ      │    │
│  └──────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Redisキャッシュ                       │
│  - セッションストア                                      │
│  - フラグメントキャッシュ                                │
│  - キャッシュ無効化戦略                                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    PostgreSQLデータベース                │
│  - 最適化されたクエリ                                    │
│  - スロークエリログ                                      │
└─────────────────────────────────────────────────────────┘
```

### パフォーマンス最適化レイヤー

| レイヤー | 最適化手法 | 効果 |
|---------|-----------|------|
| **フロントエンド** | 画像遅延読み込み、CSS/JS圧縮 | 初期読み込み時間短縮 |
| **アプリケーション** | クエリ最適化、フラグメントキャッシュ | レスポンス時間短縮 |
| **キャッシュ** | Redis、セッションストア | データベース負荷軽減 |
| **データベース** | インデックス、スロークエリ検出 | クエリ実行時間短縮 |

---

## 🔍 N+1問題の解消

### 1. Bullet gemの設定

```ruby
# Gemfile
group :development do
  gem 'bullet'
  gem 'rack-mini-profiler'
end
```

```ruby
# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
end
```

### 2. クエリ最適化パターン

#### 2.1 ブログ一覧ページ

**Before（N+1問題あり）**:
```ruby
# app/controllers/blog_controller.rb
def index
  @articles = Article.published.page(params[:page])
  # N+1: 各記事のカテゴリ・タグ・サムネイルを取得
end
```

**After（最適化済み）**:
```ruby
# app/controllers/blog_controller.rb
def index
  @articles = Article.published
                     .includes(:categories, :tags, thumbnail_attachment: :blob)
                     .order(published_at: :desc)
                     .page(params[:page])
end
```

**削減されるクエリ数**:
- Before: 1 + N（記事数） + N（カテゴリ） + N（タグ） + N（サムネイル） = 1 + 4N
- After: 5クエリ（固定）
- **効果**: 20記事の場合、81クエリ → 5クエリ（94%削減）

#### 2.2 記事詳細ページ

**Before（N+1問題あり）**:
```ruby
# app/controllers/blog_controller.rb
def show
  @article = Article.find_by(slug: params[:slug])
  # N+1: カテゴリ・タグ・関連記事のサムネイル
end
```

**After（最適化済み）**:
```ruby
# app/controllers/blog_controller.rb
def show
  @article = Article.includes(
    :categories,
    :tags,
    thumbnail_attachment: :blob,
    content_images_attachments: :blob
  ).find_by(slug: params[:slug])
  
  @related_articles = Article.published
                             .where(id: @article.related_article_ids)
                             .includes(:categories, thumbnail_attachment: :blob)
end
```

#### 2.3 管理画面記事一覧

**Before（N+1問題あり）**:
```ruby
# app/controllers/admin/articles_controller.rb
def index
  @articles = Article.all.page(params[:page])
  # N+1: カテゴリ・タグ・サムネイル
end
```

**After（最適化済み）**:
```ruby
# app/controllers/admin/articles_controller.rb
def index
  @articles = Article.includes(
    :categories,
    :tags,
    thumbnail_attachment: :blob
  ).order(updated_at: :desc).page(params[:page])
end
```

### 3. スロークエリログの設定

```ruby
# config/initializers/slow_query_logger.rb
if Rails.env.development? || Rails.env.production?
  ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
    duration = (finish - start) * 1000 # ミリ秒
    
    if duration > 100 # 100ms以上
      Rails.logger.warn "[SLOW QUERY] #{duration.round(2)}ms - #{payload[:sql]}"
      
      # 本番環境では専用ログファイルに出力
      if Rails.env.production?
        slow_query_logger = Logger.new('log/slow_query.log')
        slow_query_logger.warn "[#{Time.current}] #{duration.round(2)}ms - #{payload[:sql]}"
      end
    end
  end
end
```


---

## 🔴 Redisキャッシュ設計

### 1. Redis環境構築

#### Docker Compose設定

```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7.4.1-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

volumes:
  redis_data:
```

#### Rails設定

```ruby
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: portfolio_production

development:
  adapter: redis
  url: redis://localhost:6379/1
  channel_prefix: portfolio_development
```

```ruby
# config/cache.yml (新規作成)
production:
  adapter: redis_cache_store
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" } %>
  namespace: cache
  expires_in: 1.hour
  pool_size: 5
  pool_timeout: 5

development:
  adapter: redis_cache_store
  url: redis://localhost:6379/0
  namespace: cache
  expires_in: 5.minutes
```

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" },
  namespace: "cache",
  expires_in: 1.hour,
  pool_size: 5,
  pool_timeout: 5,
  error_handler: -> (method:, returning:, exception:) {
    Rails.logger.error("Redis error: #{exception.message}")
  }
}
```

### 2. セッションストアの移行

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :redis_store,
  servers: [
    {
      host: ENV.fetch("REDIS_HOST") { "localhost" },
      port: ENV.fetch("REDIS_PORT") { 6379 },
      db: 2,
      namespace: "session"
    }
  ],
  expire_after: 2.weeks,
  key: "_portfolio_session_#{Rails.env}",
  threadsafe: true,
  signed: true
```

### 3. フラグメントキャッシュの実装

#### 3.1 サイドバーキャッシュ

```erb
<!-- app/views/shared/_sidebar.html.erb -->
<% cache "sidebar/categories", expires_in: 1.hour do %>
  <div class="sidebar-section">
    <h3>カテゴリ</h3>
    <ul>
      <% Category.with_article_count.each do |category| %>
        <li>
          <%= link_to category.name, blog_category_path(category.slug) %>
          <span class="count">(<%= category.articles_count %>)</span>
        </li>
      <% end %>
    </ul>
  </div>
<% end %>

<% cache "sidebar/tags", expires_in: 1.hour do %>
  <div class="sidebar-section">
    <h3>人気タグ</h3>
    <div class="tag-cloud">
      <% Tag.popular(10).each do |tag| %>
        <%= link_to tag.name, blog_tag_path(tag.slug), class: "tag" %>
      <% end %>
    </div>
  </div>
<% end %>
```

#### 3.2 記事一覧キャッシュ

```erb
<!-- app/views/blog/index.html.erb -->
<% cache "articles/page-#{params[:page] || 1}", expires_in: 5.minutes do %>
  <div class="articles-list">
    <% @articles.each do |article| %>
      <%= render 'article_card', article: article %>
    <% end %>
  </div>
<% end %>
```

#### 3.3 人気記事キャッシュ

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  def self.popular(limit = 5)
    Rails.cache.fetch("popular_articles", expires_in: 10.minutes) do
      published
        .order(views_count: :desc)
        .limit(limit)
        .includes(:categories, thumbnail_attachment: :blob)
        .to_a
    end
  end
end
```

### 4. キャッシュ無効化戦略

#### 4.1 Concernの作成

```ruby
# app/models/concerns/cache_sweeper.rb
module CacheSweeper
  extend ActiveSupport::Concern

  included do
    after_commit :clear_related_caches, on: [:create, :update, :destroy]
  end

  private

  def clear_related_caches
    # サブクラスで実装
  end
end
```

#### 4.2 Articleモデルでの実装

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  include CacheSweeper

  private

  def clear_related_caches
    # 記事一覧キャッシュをクリア
    Rails.cache.delete_matched("articles/page-*")
    
    # 人気記事キャッシュをクリア
    Rails.cache.delete("popular_articles")
    
    # サイドバーキャッシュをクリア（カテゴリ・タグ変更時）
    if saved_change_to_attribute?(:category_ids) || saved_change_to_attribute?(:tag_ids)
      Rails.cache.delete("sidebar/categories")
      Rails.cache.delete("sidebar/tags")
    end
    
    Rails.logger.info "[CacheSweeper] Cleared caches for Article##{id}"
  end
end
```

#### 4.3 Categoryモデルでの実装

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  include CacheSweeper

  private

  def clear_related_caches
    Rails.cache.delete("sidebar/categories")
    Rails.cache.delete_matched("articles/page-*")
    
    Rails.logger.info "[CacheSweeper] Cleared caches for Category##{id}"
  end
end
```

#### 4.4 Tagモデルでの実装

```ruby
# app/models/tag.rb
class Tag < ApplicationRecord
  include CacheSweeper

  private

  def clear_related_caches
    Rails.cache.delete("sidebar/tags")
    Rails.cache.delete_matched("articles/page-*")
    
    Rails.logger.info "[CacheSweeper] Cleared caches for Tag##{id}"
  end
end
```

### 5. キャッシュ監視

```ruby
# app/services/cache_monitor_service.rb
class CacheMonitorService
  def self.stats
    redis = Redis.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" })
    info = redis.info
    
    {
      used_memory: info["used_memory_human"],
      connected_clients: info["connected_clients"],
      total_commands_processed: info["total_commands_processed"],
      keyspace_hits: info["keyspace_hits"],
      keyspace_misses: info["keyspace_misses"],
      hit_rate: calculate_hit_rate(info["keyspace_hits"], info["keyspace_misses"])
    }
  end

  def self.calculate_hit_rate(hits, misses)
    total = hits.to_i + misses.to_i
    return 0 if total.zero?
    
    ((hits.to_f / total) * 100).round(2)
  end
end
```

---

## 🎨 アセット最適化

### 1. CSS/JS圧縮設定

```ruby
# config/environments/production.rb
config.assets.css_compressor = :sass
config.assets.js_compressor = :terser
config.assets.compile = false
config.assets.digest = true
```

### 2. 画像遅延読み込み

#### 2.1 ヘルパーメソッド

```ruby
# app/helpers/image_helper.rb
module ImageHelper
  def lazy_image_tag(source, options = {})
    options[:loading] ||= 'lazy'
    options[:decoding] ||= 'async'
    
    image_tag(source, options)
  end
end
```

#### 2.2 ビューでの使用

```erb
<!-- app/views/blog/_article_card.html.erb -->
<div class="article-card">
  <% if article.thumbnail.attached? %>
    <%= lazy_image_tag article.thumbnail, 
                       alt: article.title,
                       class: "article-thumbnail" %>
  <% end %>
  
  <h3><%= link_to article.title, blog_article_path(article.slug) %></h3>
  <p><%= article.excerpt %></p>
</div>
```

```erb
<!-- app/views/blog/show.html.erb -->
<article class="prose">
  <%= sanitize article.content_html, tags: %w[img], attributes: %w[src alt loading] %>
</article>

<script>
  // 本文内の画像にloading="lazy"を追加
  document.querySelectorAll('article.prose img').forEach(img => {
    if (!img.hasAttribute('loading')) {
      img.setAttribute('loading', 'lazy');
      img.setAttribute('decoding', 'async');
    }
  });
</script>
```

---

## 📊 パフォーマンス測定

### 1. rack-mini-profilerの設定

```ruby
# Gemfile
group :development do
  gem 'rack-mini-profiler'
  gem 'memory_profiler'
  gem 'stackprof'
end
```

```ruby
# config/initializers/rack_profiler.rb
if Rails.env.development?
  require 'rack-mini-profiler'
  
  Rack::MiniProfilerRails.initialize!(Rails.application)
  
  Rack::MiniProfiler.config.position = 'bottom-right'
  Rack::MiniProfiler.config.start_hidden = false
end
```

### 2. パフォーマンスベンチマーク

```ruby
# lib/tasks/performance.rake
namespace :performance do
  desc "Run performance benchmarks"
  task benchmark: :environment do
    require 'benchmark'
    
    puts "=== Blog Index Page ==="
    time = Benchmark.realtime do
      Article.published
             .includes(:categories, :tags, thumbnail_attachment: :blob)
             .page(1)
             .to_a
    end
    puts "Time: #{(time * 1000).round(2)}ms"
    
    puts "\n=== Article Show Page ==="
    article = Article.published.first
    time = Benchmark.realtime do
      Article.includes(
        :categories,
        :tags,
        thumbnail_attachment: :blob,
        content_images_attachments: :blob
      ).find(article.id)
    end
    puts "Time: #{(time * 1000).round(2)}ms"
    
    puts "\n=== Cache Hit Rate ==="
    stats = CacheMonitorService.stats
    puts "Hit Rate: #{stats[:hit_rate]}%"
    puts "Used Memory: #{stats[:used_memory]}"
  end
end
```


---

## 🧪 テスト仕様

### 1. パフォーマンステスト

```ruby
# spec/performance/blog_performance_spec.rb
require 'rails_helper'

RSpec.describe 'Blog Performance', type: :request do
  before do
    # テストデータ作成
    create_list(:article, 20, :published, :with_thumbnail)
  end

  describe 'GET /blog' do
    it 'loads within 2 seconds' do
      start_time = Time.current
      get blog_path
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 2.0
    end

    it 'does not have N+1 queries' do
      # ウォームアップ
      get blog_path
      
      # クエリ数を測定
      expect {
        get blog_path
      }.to perform_queries(count: ..10) # 10クエリ以下
    end
  end

  describe 'GET /blog/:slug' do
    let(:article) { Article.published.first }

    it 'loads within 1.5 seconds' do
      start_time = Time.current
      get blog_article_path(article.slug)
      end_time = Time.current
      
      expect(response).to have_http_status(:success)
      expect(end_time - start_time).to be < 1.5
    end
  end
end
```

### 2. キャッシュテスト

```ruby
# spec/models/concerns/cache_sweeper_spec.rb
require 'rails_helper'

RSpec.describe CacheSweeper do
  describe Article do
    let(:article) { create(:article, :published) }

    before do
      # キャッシュを事前に作成
      Rails.cache.write("articles/page-1", "cached content")
      Rails.cache.write("popular_articles", "cached popular")
    end

    it 'clears article list cache on create' do
      expect {
        create(:article, :published)
      }.to change { Rails.cache.exist?("articles/page-1") }.from(true).to(false)
    end

    it 'clears article list cache on update' do
      expect {
        article.update(title: "Updated Title")
      }.to change { Rails.cache.exist?("articles/page-1") }.from(true).to(false)
    end

    it 'clears popular articles cache on destroy' do
      expect {
        article.destroy
      }.to change { Rails.cache.exist?("popular_articles") }.from(true).to(false)
    end
  end

  describe Category do
    let(:category) { create(:category) }

    before do
      Rails.cache.write("sidebar/categories", "cached categories")
    end

    it 'clears sidebar cache on update' do
      expect {
        category.update(name: "Updated Category")
      }.to change { Rails.cache.exist?("sidebar/categories") }.from(true).to(false)
    end
  end
end
```

### 3. Redis接続テスト

```ruby
# spec/services/cache_monitor_service_spec.rb
require 'rails_helper'

RSpec.describe CacheMonitorService do
  describe '.stats' do
    it 'returns Redis statistics' do
      stats = described_class.stats

      expect(stats).to include(
        :used_memory,
        :connected_clients,
        :total_commands_processed,
        :keyspace_hits,
        :keyspace_misses,
        :hit_rate
      )
    end

    it 'calculates hit rate correctly' do
      # Redisにキャッシュを書き込み・読み込み
      Rails.cache.write("test_key", "test_value")
      Rails.cache.read("test_key")
      Rails.cache.read("non_existent_key")

      stats = described_class.stats
      expect(stats[:hit_rate]).to be >= 0
      expect(stats[:hit_rate]).to be <= 100
    end
  end

  describe '.calculate_hit_rate' do
    it 'returns 0 when no hits or misses' do
      expect(described_class.calculate_hit_rate(0, 0)).to eq(0)
    end

    it 'calculates correct hit rate' do
      expect(described_class.calculate_hit_rate(80, 20)).to eq(80.0)
    end
  end
end
```

### 4. N+1問題検出テスト

```ruby
# spec/requests/blog_n_plus_one_spec.rb
require 'rails_helper'

RSpec.describe 'Blog N+1 Detection', type: :request do
  before do
    create_list(:article, 5, :published, :with_categories, :with_tags, :with_thumbnail)
  end

  describe 'GET /blog' do
    it 'does not trigger N+1 queries' do
      # Bulletを有効化
      Bullet.enable = true
      Bullet.raise = true

      expect {
        get blog_path
      }.not_to raise_error
    end
  end

  describe 'GET /blog/:slug' do
    let(:article) { Article.published.first }

    it 'does not trigger N+1 queries' do
      Bullet.enable = true
      Bullet.raise = true

      expect {
        get blog_article_path(article.slug)
      }.not_to raise_error
    end
  end
end
```

### 5. 画像遅延読み込みテスト

```ruby
# spec/helpers/image_helper_spec.rb
require 'rails_helper'

RSpec.describe ImageHelper, type: :helper do
  describe '#lazy_image_tag' do
    it 'adds loading="lazy" attribute' do
      result = helper.lazy_image_tag('test.jpg', alt: 'Test')
      
      expect(result).to include('loading="lazy"')
      expect(result).to include('decoding="async"')
      expect(result).to include('alt="Test"')
    end

    it 'allows custom loading attribute' do
      result = helper.lazy_image_tag('test.jpg', loading: 'eager')
      
      expect(result).to include('loading="eager"')
    end
  end
end
```

### 6. 統合テスト

```ruby
# spec/system/performance_spec.rb
require 'rails_helper'

RSpec.describe 'Performance Integration', type: :system do
  before do
    driven_by(:selenium_headless)
    create_list(:article, 10, :published, :with_thumbnail)
  end

  describe 'Blog page with cache' do
    it 'loads quickly on second visit' do
      # 1回目の訪問（キャッシュなし）
      visit blog_path
      expect(page).to have_content('Blog')

      # 2回目の訪問（キャッシュあり）
      start_time = Time.current
      visit blog_path
      end_time = Time.current

      expect(page).to have_content('Blog')
      expect(end_time - start_time).to be < 1.0 # 1秒以内
    end
  end

  describe 'Image lazy loading' do
    it 'images have loading="lazy" attribute' do
      visit blog_path

      images = page.all('img')
      expect(images).not_to be_empty
      
      images.each do |img|
        expect(img[:loading]).to eq('lazy')
      end
    end
  end
end
```

---

## 📝 実装チェックリスト

### N+1問題の解消
- [ ] Bullet gemのインストール・設定
- [ ] ブログ一覧ページのクエリ最適化
- [ ] 記事詳細ページのクエリ最適化
- [ ] 管理画面のクエリ最適化
- [ ] スロークエリログの設定

### Redisキャッシュ
- [ ] Docker ComposeにRedis追加
- [ ] cache.ymlの作成
- [ ] セッションストアの移行
- [ ] サイドバーキャッシュの実装
- [ ] 記事一覧キャッシュの実装
- [ ] 人気記事キャッシュの実装
- [ ] CacheSweeperの実装
- [ ] キャッシュ無効化の実装
- [ ] CacheMonitorServiceの実装

### アセット最適化
- [ ] CSS/JS圧縮設定の確認
- [ ] lazy_image_tagヘルパーの実装
- [ ] ビューでの画像遅延読み込み適用

### パフォーマンス測定
- [ ] rack-mini-profilerのインストール・設定
- [ ] パフォーマンスベンチマークタスクの作成

### テスト
- [ ] パフォーマンステストの実装
- [ ] キャッシュテストの実装
- [ ] Redis接続テストの実装
- [ ] N+1問題検出テストの実装
- [ ] 画像遅延読み込みテストの実装
- [ ] 統合テストの実装

---

## 📊 期待される効果

### パフォーマンス改善
- ブログ一覧ページ: 3秒 → 1.5秒（50%改善）
- 記事詳細ページ: 2秒 → 1秒（50%改善）
- データベースクエリ数: 81クエリ → 5クエリ（94%削減）

### キャッシュヒット率
- サイドバーキャッシュ: 90%以上
- 記事一覧キャッシュ: 80%以上

### ユーザー体験
- ページ読み込みの体感速度向上
- スムーズなスクロール
- 画像の段階的表示

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**ステータス**: レビュー待ち
