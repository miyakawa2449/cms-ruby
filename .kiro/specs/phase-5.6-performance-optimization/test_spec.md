# Phase 5.6: パフォーマンス最適化 - テスト仕様書

**Phase**: 5.6  
**機能名**: パフォーマンス最適化  
**作成日**: 2026-01-18  
**作成者**: Kiro

---

## 📋 目次

1. [テスト戦略](#テスト戦略)
2. [ユニットテスト](#ユニットテスト)
3. [統合テスト](#統合テスト)
4. [パフォーマンステスト](#パフォーマンステスト)
5. [E2Eテスト](#e2eテスト)
6. [テスト実行](#テスト実行)

---

## 🎯 テスト戦略

### テストピラミッド

```
        /\
       /E2E\          5% - システム全体の動作確認
      /------\
     /統合テスト\      15% - コンポーネント間の連携
    /----------\
   /ユニットテスト\    80% - 個別機能の動作確認
  /--------------\
```

### テスト目標

| カテゴリ | 目標カバレッジ | 優先度 |
|---------|--------------|--------|
| ユニットテスト | 90%以上 | 高 |
| 統合テスト | 80%以上 | 高 |
| パフォーマンステスト | 100% | 高 |
| E2Eテスト | 主要フロー | 中 |

---

## 🧪 ユニットテスト

### 1. CacheSweeperモジュール

```ruby
# spec/models/concerns/cache_sweeper_spec.rb
require 'rails_helper'

RSpec.describe CacheSweeper do
  describe Article do
    let(:article) { create(:article, :published) }

    before do
      Rails.cache.write("articles/page-1", "cached content")
      Rails.cache.write("popular_articles", "cached popular")
      Rails.cache.write("sidebar/categories", "cached categories")
      Rails.cache.write("sidebar/tags", "cached tags")
    end

    describe 'on create' do
      it 'clears article list cache' do
        expect {
          create(:article, :published)
        }.to change { Rails.cache.exist?("articles/page-1") }.from(true).to(false)
      end

      it 'clears popular articles cache' do
        expect {
          create(:article, :published)
        }.to change { Rails.cache.exist?("popular_articles") }.from(true).to(false)
      end
    end

    describe 'on update' do
      context 'when title is updated' do
        it 'clears article list cache' do
          expect {
            article.update(title: "Updated Title")
          }.to change { Rails.cache.exist?("articles/page-1") }.from(true).to(false)
        end
      end

      context 'when categories are updated' do
        it 'clears sidebar categories cache' do
          expect {
            article.update(category_ids: [create(:category).id])
          }.to change { Rails.cache.exist?("sidebar/categories") }.from(true).to(false)
        end
      end

      context 'when tags are updated' do
        it 'clears sidebar tags cache' do
          expect {
            article.update(tag_ids: [create(:tag).id])
          }.to change { Rails.cache.exist?("sidebar/tags") }.from(true).to(false)
        end
      end
    end

    describe 'on destroy' do
      it 'clears all related caches' do
        expect {
          article.destroy
        }.to change { Rails.cache.exist?("articles/page-1") }.from(true).to(false)
         .and change { Rails.cache.exist?("popular_articles") }.from(true).to(false)
      end
    end
  end

  describe Category do
    let(:category) { create(:category) }

    before do
      Rails.cache.write("sidebar/categories", "cached categories")
      Rails.cache.write("articles/page-1", "cached content")
    end

    it 'clears sidebar cache on update' do
      expect {
        category.update(name: "Updated Category")
      }.to change { Rails.cache.exist?("sidebar/categories") }.from(true).to(false)
    end

    it 'clears article list cache on update' do
      expect {
        category.update(name: "Updated Category")
      }.to change { Rails.cache.exist?("articles/page-1") }.from(true).to(false)
    end
  end

  describe Tag do
    let(:tag) { create(:tag) }

    before do
      Rails.cache.write("sidebar/tags", "cached tags")
      Rails.cache.write("articles/page-1", "cached content")
    end

    it 'clears sidebar cache on update' do
      expect {
        tag.update(name: "Updated Tag")
      }.to change { Rails.cache.exist?("sidebar/tags") }.from(true).to(false)
    end

    it 'clears article list cache on update' do
      expect {
        tag.update(name: "Updated Tag")
      }.to change { Rails.cache.exist?("articles/page-1") }.from(true).to(false)
    end
  end
end
```

### 2. CacheMonitorService

```ruby
# spec/services/cache_monitor_service_spec.rb
require 'rails_helper'

RSpec.describe CacheMonitorService do
  describe '.stats' do
    it 'returns Redis statistics' do
      stats = described_class.stats

      expect(stats).to be_a(Hash)
      expect(stats).to include(
        :used_memory,
        :connected_clients,
        :total_commands_processed,
        :keyspace_hits,
        :keyspace_misses,
        :hit_rate
      )
    end

    it 'returns valid data types' do
      stats = described_class.stats

      expect(stats[:used_memory]).to be_a(String)
      expect(stats[:connected_clients]).to be_a(String)
      expect(stats[:total_commands_processed]).to be_a(String)
      expect(stats[:hit_rate]).to be_a(Float)
    end

    it 'calculates hit rate correctly' do
      # キャッシュ操作
      Rails.cache.write("test_key_1", "value1")
      Rails.cache.write("test_key_2", "value2")
      Rails.cache.read("test_key_1") # hit
      Rails.cache.read("test_key_2") # hit
      Rails.cache.read("non_existent") # miss

      stats = described_class.stats
      expect(stats[:hit_rate]).to be >= 0
      expect(stats[:hit_rate]).to be <= 100
    end
  end

  describe '.calculate_hit_rate' do
    it 'returns 0 when no hits or misses' do
      expect(described_class.calculate_hit_rate(0, 0)).to eq(0)
    end

    it 'returns 100 when all hits' do
      expect(described_class.calculate_hit_rate(100, 0)).to eq(100.0)
    end

    it 'returns 0 when all misses' do
      expect(described_class.calculate_hit_rate(0, 100)).to eq(0.0)
    end

    it 'calculates correct hit rate' do
      expect(described_class.calculate_hit_rate(80, 20)).to eq(80.0)
      expect(described_class.calculate_hit_rate(75, 25)).to eq(75.0)
      expect(described_class.calculate_hit_rate(50, 50)).to eq(50.0)
    end
  end
end
```

### 3. ImageHelper

```ruby
# spec/helpers/image_helper_spec.rb
require 'rails_helper'

RSpec.describe ImageHelper, type: :helper do
  describe '#lazy_image_tag' do
    it 'adds loading="lazy" attribute by default' do
      result = helper.lazy_image_tag('test.jpg')
      
      expect(result).to include('loading="lazy"')
      expect(result).to include('decoding="async"')
    end

    it 'includes alt attribute' do
      result = helper.lazy_image_tag('test.jpg', alt: 'Test Image')
      
      expect(result).to include('alt="Test Image"')
    end

    it 'includes class attribute' do
      result = helper.lazy_image_tag('test.jpg', class: 'thumbnail')
      
      expect(result).to include('class="thumbnail"')
    end

    it 'allows custom loading attribute' do
      result = helper.lazy_image_tag('test.jpg', loading: 'eager')
      
      expect(result).to include('loading="eager"')
      expect(result).not_to include('loading="lazy"')
    end

    it 'allows custom decoding attribute' do
      result = helper.lazy_image_tag('test.jpg', decoding: 'sync')
      
      expect(result).to include('decoding="sync"')
      expect(result).not_to include('decoding="async"')
    end
  end
end
```

---

## 🔗 統合テスト

### 1. ブログコントローラー

```ruby
# spec/requests/blog_spec.rb
require 'rails_helper'

RSpec.describe 'Blog', type: :request do
  before do
    create_list(:article, 20, :published, :with_categories, :with_tags, :with_thumbnail)
  end

  describe 'GET /blog' do
    it 'returns success' do
      get blog_path
      expect(response).to have_http_status(:success)
    end

    it 'uses cache on second request' do
      # 1回目のリクエスト（キャッシュなし）
      get blog_path
      expect(Rails.cache.exist?("articles/page-1")).to be true

      # 2回目のリクエスト（キャッシュあり）
      expect(Rails.cache).to receive(:read).with("articles/page-1").and_call_original
      get blog_path
    end

    it 'invalidates cache when article is created' do
      get blog_path
      expect(Rails.cache.exist?("articles/page-1")).to be true

      create(:article, :published)
      expect(Rails.cache.exist?("articles/page-1")).to be false
    end
  end

  describe 'GET /blog/:slug' do
    let(:article) { Article.published.first }

    it 'returns success' do
      get blog_article_path(article.slug)
      expect(response).to have_http_status(:success)
    end

    it 'loads article with associations' do
      get blog_article_path(article.slug)
      
      expect(assigns(:article)).to be_present
      expect(assigns(:article).categories).to be_loaded
      expect(assigns(:article).tags).to be_loaded
    end
  end
end
```

### 2. セッションストア

```ruby
# spec/requests/session_store_spec.rb
require 'rails_helper'

RSpec.describe 'Session Store', type: :request do
  let(:admin_user) { create(:admin_user) }

  describe 'Redis session store' do
    it 'stores session in Redis' do
      post admin_user_session_path, params: {
        admin_user: {
          email: admin_user.email,
          password: admin_user.password
        }
      }

      expect(response).to redirect_to(admin_dashboard_path)
      
      # Redisにセッションが保存されているか確認
      redis = Redis.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/2" })
      keys = redis.keys("session:*")
      expect(keys).not_to be_empty
    end

    it 'retrieves session from Redis' do
      # ログイン
      post admin_user_session_path, params: {
        admin_user: {
          email: admin_user.email,
          password: admin_user.password
        }
      }

      # セッションを使用してアクセス
      get admin_dashboard_path
      expect(response).to have_http_status(:success)
    end

    it 'expires session after configured time' do
      # セッション有効期限のテスト（実際の時間経過は不要）
      post admin_user_session_path, params: {
        admin_user: {
          email: admin_user.email,
          password: admin_user.password
        }
      }

      # セッションのTTLを確認
      redis = Redis.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/2" })
      keys = redis.keys("session:*")
      ttl = redis.ttl(keys.first)
      
      expect(ttl).to be > 0
      expect(ttl).to be <= 2.weeks.to_i
    end
  end
end
```

---

## ⚡ パフォーマンステスト

### 1. ページ読み込み時間

```ruby
# spec/performance/page_load_time_spec.rb
require 'rails_helper'

RSpec.describe 'Page Load Time', type: :request do
  before do
    create_list(:article, 20, :published, :with_categories, :with_tags, :with_thumbnail)
  end

  describe 'GET /blog' do
    it 'loads within 2 seconds' do
      start_time = Time.current
      get blog_path
      end_time = Time.current
      
      duration = end_time - start_time
      
      expect(response).to have_http_status(:success)
      expect(duration).to be < 2.0
      
      puts "Blog index page load time: #{(duration * 1000).round(2)}ms"
    end

    it 'loads faster on second request (with cache)' do
      # 1回目（キャッシュなし）
      start_time_1 = Time.current
      get blog_path
      end_time_1 = Time.current
      duration_1 = end_time_1 - start_time_1

      # 2回目（キャッシュあり）
      start_time_2 = Time.current
      get blog_path
      end_time_2 = Time.current
      duration_2 = end_time_2 - start_time_2

      expect(duration_2).to be < duration_1
      
      puts "1st request: #{(duration_1 * 1000).round(2)}ms"
      puts "2nd request: #{(duration_2 * 1000).round(2)}ms"
      puts "Improvement: #{((1 - duration_2 / duration_1) * 100).round(2)}%"
    end
  end

  describe 'GET /blog/:slug' do
    let(:article) { Article.published.first }

    it 'loads within 1.5 seconds' do
      start_time = Time.current
      get blog_article_path(article.slug)
      end_time = Time.current
      
      duration = end_time - start_time
      
      expect(response).to have_http_status(:success)
      expect(duration).to be < 1.5
      
      puts "Article show page load time: #{(duration * 1000).round(2)}ms"
    end
  end

  describe 'GET /' do
    it 'loads within 2 seconds' do
      start_time = Time.current
      get root_path
      end_time = Time.current
      
      duration = end_time - start_time
      
      expect(response).to have_http_status(:success)
      expect(duration).to be < 2.0
      
      puts "Portfolio page load time: #{(duration * 1000).round(2)}ms"
    end
  end

  describe 'GET /admin/articles' do
    let(:admin_user) { create(:admin_user) }

    before do
      sign_in admin_user
    end

    it 'loads within 3 seconds' do
      start_time = Time.current
      get admin_articles_path
      end_time = Time.current
      
      duration = end_time - start_time
      
      expect(response).to have_http_status(:success)
      expect(duration).to be < 3.0
      
      puts "Admin articles page load time: #{(duration * 1000).round(2)}ms"
    end
  end
end
```

### 2. N+1問題検出

```ruby
# spec/performance/n_plus_one_spec.rb
require 'rails_helper'

RSpec.describe 'N+1 Detection', type: :request do
  before do
    create_list(:article, 10, :published, :with_categories, :with_tags, :with_thumbnail)
    
    # Bulletを有効化
    Bullet.enable = true
    Bullet.raise = true
  end

  after do
    Bullet.enable = false
  end

  describe 'GET /blog' do
    it 'does not trigger N+1 queries' do
      expect {
        get blog_path
      }.not_to raise_error
    end

    it 'performs limited number of queries' do
      query_count = 0
      
      ActiveSupport::Notifications.subscribe('sql.active_record') do
        query_count += 1
      end

      get blog_path
      
      expect(query_count).to be <= 10
      puts "Blog index queries: #{query_count}"
    end
  end

  describe 'GET /blog/:slug' do
    let(:article) { Article.published.first }

    it 'does not trigger N+1 queries' do
      expect {
        get blog_article_path(article.slug)
      }.not_to raise_error
    end
  end

  describe 'GET /admin/articles' do
    let(:admin_user) { create(:admin_user) }

    before do
      sign_in admin_user
    end

    it 'does not trigger N+1 queries' do
      expect {
        get admin_articles_path
      }.not_to raise_error
    end
  end
end
```

### 3. キャッシュヒット率

```ruby
# spec/performance/cache_hit_rate_spec.rb
require 'rails_helper'

RSpec.describe 'Cache Hit Rate', type: :request do
  before do
    create_list(:article, 20, :published, :with_categories, :with_tags)
    Rails.cache.clear
  end

  describe 'sidebar cache' do
    it 'achieves high hit rate' do
      # 10回リクエスト
      10.times { get blog_path }

      stats = CacheMonitorService.stats
      expect(stats[:hit_rate]).to be >= 80.0
      
      puts "Sidebar cache hit rate: #{stats[:hit_rate]}%"
    end
  end

  describe 'article list cache' do
    it 'caches article list' do
      # 1回目（キャッシュなし）
      get blog_path
      expect(Rails.cache.exist?("articles/page-1")).to be true

      # 2回目以降（キャッシュあり）
      5.times do
        get blog_path
        expect(Rails.cache.exist?("articles/page-1")).to be true
      end
    end
  end
end
```

---

## 🖥️ E2Eテスト

### 1. ブログページ

```ruby
# spec/system/blog_performance_spec.rb
require 'rails_helper'

RSpec.describe 'Blog Performance', type: :system do
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
      expect(end_time - start_time).to be < 1.0
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

    it 'images load progressively on scroll' do
      visit blog_path

      # 最初は一部の画像のみ読み込まれる
      initial_loaded = page.all('img[src]').count
      
      # スクロール
      page.execute_script('window.scrollTo(0, document.body.scrollHeight)')
      sleep 1

      # スクロール後はより多くの画像が読み込まれる
      after_scroll_loaded = page.all('img[src]').count
      
      expect(after_scroll_loaded).to be >= initial_loaded
    end
  end
end
```

---

## 🚀 テスト実行

### 全テスト実行

```bash
# 全テスト
bundle exec rspec

# パフォーマンステストのみ
bundle exec rspec spec/performance

# N+1問題検出テスト
bundle exec rspec spec/performance/n_plus_one_spec.rb

# キャッシュテスト
bundle exec rspec spec/models/concerns/cache_sweeper_spec.rb
bundle exec rspec spec/services/cache_monitor_service_spec.rb
```

### パフォーマンスベンチマーク

```bash
# Rakeタスク
bundle exec rake performance:benchmark

# 出力例:
# === Blog Index Page ===
# Time: 150.23ms
# Queries: 5
#
# === Article Show Page ===
# Time: 85.67ms
# Queries: 4
#
# === Cache Hit Rate ===
# Hit Rate: 87.5%
# Used Memory: 2.5MB
```

---

## 📊 テストカバレッジ目標

| カテゴリ | ファイル数 | テスト数 | カバレッジ目標 |
|---------|-----------|---------|--------------|
| ユニットテスト | 3 | 30+ | 90%以上 |
| 統合テスト | 2 | 15+ | 80%以上 |
| パフォーマンステスト | 3 | 20+ | 100% |
| E2Eテスト | 1 | 5+ | 主要フロー |
| **合計** | **9** | **70+** | **85%以上** |

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**ステータス**: レビュー待ち
