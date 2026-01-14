# Phase 4.4 基本SEO機能実装 - 仕様書

## 📋 概要

**機能名**: 基本SEO機能（RSS/Atom、sitemap.xml、robots.txt）  
**Phase**: Phase 4.4  
**優先度**: 高（MVP公開済みだが基本SEO未実装のため早期対応必要）  
**実装期間**: 2-3日  
**担当**: Claude Code

## 🎯 目的

MVP公開後の検索エンジン最適化を強化し、以下を実現する：
1. 検索エンジンのクロール効率向上（sitemap.xml）
2. RSSリーダーでの記事購読対応（RSS/Atom）
3. クローラー制御の適切な設定（robots.txt）

## 📊 現状分析

### 実装済み
- ✅ OGP/Twitter Card（全ページ）
- ✅ 構造化データ（JSON-LD）
- ✅ メタタグ最適化

### 未実装（本仕様の対象）
- ❌ sitemap.xml
- ❌ RSS/Atomフィード
- ❌ robots.txt設定

## 📝 要件定義

### Requirement 1: sitemap.xml自動生成

**User Story**: 検索エンジンのクローラーとして、サイトの全URLを効率的に発見したい

#### Acceptance Criteria
1. WHEN サイトにアクセスすると、THE System SHALL `/sitemap.xml`でXMLサイトマップを提供する
2. WHEN 記事が公開されると、THE System SHALL サイトマップに自動的に追加する
3. THE Sitemap SHALL 以下のURLを含む：
   - トップページ（/）
   - My Storyページ（/my-story）
   - ブログ一覧（/blog）
   - 公開記事詳細（/blog/:slug）
   - カテゴリページ（/blog/categories/:slug）
4. THE Sitemap SHALL 各URLに以下の情報を含む：
   - `<loc>`: URL
   - `<lastmod>`: 最終更新日時
   - `<changefreq>`: 更新頻度
   - `<priority>`: 優先度（0.0-1.0）
5. WHEN 記事が更新されると、THE System SHALL サイトマップの`lastmod`を更新する


### Requirement 2: RSSフィード提供

**User Story**: ブログ読者として、RSSリーダーで新着記事を購読したい

#### Acceptance Criteria
1. WHEN `/feed.rss`にアクセスすると、THE System SHALL RSS 2.0形式のフィードを提供する
2. THE RSS Feed SHALL 最新20件の公開記事を含む
3. THE RSS Feed SHALL 各記事に以下の情報を含む：
   - `<title>`: 記事タイトル
   - `<link>`: 記事URL
   - `<description>`: 記事の抜粋（excerpt）
   - `<pubDate>`: 公開日時
   - `<guid>`: 一意識別子（記事URL）
   - `<category>`: カテゴリ名
4. WHEN 記事が公開されると、THE System SHALL フィードに自動的に追加する
5. THE RSS Feed SHALL 適切なContent-Type（`application/rss+xml`）で配信する

### Requirement 3: Atomフィード提供

**User Story**: ブログ読者として、Atom形式のフィードで記事を購読したい

#### Acceptance Criteria
1. WHEN `/feed.atom`にアクセスすると、THE System SHALL Atom 1.0形式のフィードを提供する
2. THE Atom Feed SHALL 最新20件の公開記事を含む
3. THE Atom Feed SHALL 各記事に以下の情報を含む：
   - `<title>`: 記事タイトル
   - `<link>`: 記事URL
   - `<summary>`: 記事の抜粋
   - `<updated>`: 更新日時
   - `<published>`: 公開日時
   - `<id>`: 一意識別子
   - `<category>`: カテゴリ名
4. THE Atom Feed SHALL 適切なContent-Type（`application/atom+xml`）で配信する

### Requirement 4: robots.txt設定

**User Story**: 検索エンジンのクローラーとして、クロール可能なページとsitemapの場所を知りたい

#### Acceptance Criteria
1. WHEN `/robots.txt`にアクセスすると、THE System SHALL robots.txtファイルを提供する
2. THE robots.txt SHALL sitemap.xmlの場所を指定する
3. THE robots.txt SHALL 管理画面（/admin）へのクロールを禁止する
4. THE robots.txt SHALL 公開ページへのクロールを許可する
5. THE robots.txt SHALL 適切なUser-agent指定を含む

### Requirement 5: フィードリンクの表示

**User Story**: ブログ読者として、RSSフィードの存在を発見したい

#### Acceptance Criteria
1. WHEN ブログページを表示すると、THE System SHALL `<head>`内にRSSフィードのリンクを含む
2. WHEN ブログページを表示すると、THE System SHALL `<head>`内にAtomフィードのリンクを含む
3. WHEN ブログページを表示すると、THE System SHALL サイドバーにRSS購読リンクを表示する
4. THE RSS Link SHALL 適切なアイコンとテキストで視覚的に識別可能である


## 🏗 設計

### アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                        Public Routes                         │
├─────────────────────────────────────────────────────────────┤
│  GET /sitemap.xml      → SitemapsController#index           │
│  GET /feed.rss         → FeedsController#rss                │
│  GET /feed.atom        → FeedsController#atom               │
│  GET /robots.txt       → Static File (public/robots.txt)    │
└─────────────────────────────────────────────────────────────┘
```

### データモデル

既存のモデルを使用（新規モデル不要）：
- `Article`: 記事データ（公開済みのみ対象）
- `Category`: カテゴリデータ

### コントローラー設計

#### SitemapsController
```ruby
class SitemapsController < ApplicationController
  def index
    @articles = Article.published.order(updated_at: :desc)
    @categories = Category.with_published_articles
    
    respond_to do |format|
      format.xml
    end
  end
end
```

#### FeedsController
```ruby
class FeedsController < ApplicationController
  def rss
    @articles = Article.published.order(published_at: :desc).limit(20)
    
    respond_to do |format|
      format.rss { render layout: false }
    end
  end
  
  def atom
    @articles = Article.published.order(published_at: :desc).limit(20)
    
    respond_to do |format|
      format.atom { render layout: false }
    end
  end
end
```

### ビュー設計

#### sitemap.xml.builder
```ruby
xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # 固定ページ
  xml.url do
    xml.loc root_url
    xml.lastmod Time.current.iso8601
    xml.changefreq "daily"
    xml.priority 1.0
  end
  
  # 記事
  @articles.each do |article|
    xml.url do
      xml.loc blog_article_url(article.slug)
      xml.lastmod article.updated_at.iso8601
      xml.changefreq "weekly"
      xml.priority 0.8
    end
  end
end
```

#### feed.rss.builder
```ruby
xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "ブログタイトル"
    xml.description "ブログの説明"
    xml.link blog_index_url
    
    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.link blog_article_url(article.slug)
        xml.description article.excerpt
        xml.pubDate article.published_at.rfc822
        xml.guid blog_article_url(article.slug)
      end
    end
  end
end
```


### robots.txt設計

```
# public/robots.txt
User-agent: *
Allow: /
Disallow: /admin
Disallow: /admin/*

# Sitemap
Sitemap: https://yourdomain.com/sitemap.xml
```

### ルーティング設計

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # SEO関連
  get '/sitemap.xml', to: 'sitemaps#index', defaults: { format: 'xml' }
  get '/feed.rss', to: 'feeds#rss', defaults: { format: 'rss' }
  get '/feed.atom', to: 'feeds#atom', defaults: { format: 'atom' }
  
  # 既存のルート...
end
```

## 🧪 テスト戦略

### Unit Tests（RSpec）

#### SitemapsController
```ruby
describe SitemapsController, type: :controller do
  describe 'GET #index' do
    it 'returns XML format' do
      get :index, format: :xml
      expect(response.content_type).to eq('application/xml')
    end
    
    it 'includes published articles' do
      article = create(:article, :published)
      get :index, format: :xml
      expect(response.body).to include(article.slug)
    end
    
    it 'excludes draft articles' do
      article = create(:article, :draft)
      get :index, format: :xml
      expect(response.body).not_to include(article.slug)
    end
  end
end
```

#### FeedsController
```ruby
describe FeedsController, type: :controller do
  describe 'GET #rss' do
    it 'returns RSS format' do
      get :rss, format: :rss
      expect(response.content_type).to eq('application/rss+xml')
    end
    
    it 'limits to 20 articles' do
      create_list(:article, 25, :published)
      get :rss, format: :rss
      # XMLパース後、itemが20件であることを確認
    end
  end
  
  describe 'GET #atom' do
    it 'returns Atom format' do
      get :atom, format: :atom
      expect(response.content_type).to eq('application/atom+xml')
    end
  end
end
```

### Integration Tests

```ruby
describe 'SEO Features', type: :request do
  it 'sitemap.xml is accessible' do
    get '/sitemap.xml'
    expect(response).to have_http_status(:success)
  end
  
  it 'feed.rss is accessible' do
    get '/feed.rss'
    expect(response).to have_http_status(:success)
  end
  
  it 'robots.txt is accessible' do
    get '/robots.txt'
    expect(response).to have_http_status(:success)
  end
end
```


## 📋 実装タスク

### Task 1: sitemap.xml実装
- [ ] 1.1 SitemapsControllerの作成
  - `app/controllers/sitemaps_controller.rb`
  - indexアクションの実装
  - _Requirements: 1.1, 1.2_
  
- [ ] 1.2 sitemap.xml.builderビューの作成
  - `app/views/sitemaps/index.xml.builder`
  - 固定ページURL追加（/, /my-story, /blog）
  - 記事URL追加（公開済みのみ）
  - カテゴリURL追加
  - lastmod, changefreq, priority設定
  - _Requirements: 1.3, 1.4, 1.5_
  
- [ ] 1.3 ルーティング追加
  - `config/routes.rb`に`get '/sitemap.xml'`追加
  - _Requirements: 1.1_

### Task 2: RSSフィード実装
- [ ] 2.1 FeedsControllerの作成
  - `app/controllers/feeds_controller.rb`
  - rssアクションの実装
  - 最新20件取得ロジック
  - _Requirements: 2.1, 2.2_
  
- [ ] 2.2 feed.rss.builderビューの作成
  - `app/views/feeds/rss.rss.builder`
  - RSS 2.0形式のXML生成
  - チャンネル情報設定
  - 記事情報設定（title, link, description, pubDate, guid, category）
  - _Requirements: 2.3, 2.4, 2.5_
  
- [ ] 2.3 ルーティング追加
  - `config/routes.rb`に`get '/feed.rss'`追加
  - _Requirements: 2.1_

### Task 3: Atomフィード実装
- [ ] 3.1 FeedsController#atomアクションの追加
  - atomアクションの実装
  - _Requirements: 3.1, 3.2_
  
- [ ] 3.2 feed.atom.builderビューの作成
  - `app/views/feeds/atom.atom.builder`
  - Atom 1.0形式のXML生成
  - フィード情報設定
  - エントリ情報設定（title, link, summary, updated, published, id, category）
  - _Requirements: 3.3, 3.4_
  
- [ ] 3.3 ルーティング追加
  - `config/routes.rb`に`get '/feed.atom'`追加
  - _Requirements: 3.1_

### Task 4: robots.txt設定
- [ ] 4.1 robots.txtファイルの作成・更新
  - `public/robots.txt`の編集
  - User-agent設定
  - Allow/Disallow設定
  - Sitemap URL指定
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

### Task 5: フィードリンクの表示
- [ ] 5.1 ブログレイアウトへのフィードリンク追加
  - `app/views/layouts/blog.html.erb`の`<head>`内に追加
  - RSS link tag追加
  - Atom link tag追加
  - _Requirements: 5.1, 5.2_
  
- [ ] 5.2 サイドバーへのRSS購読リンク追加
  - `app/views/blog/_sidebar.html.erb`に追加
  - RSSアイコン付きリンク
  - Atomリンク（オプション）
  - _Requirements: 5.3, 5.4_

### Task 6: テスト実装
- [ ] 6.1 SitemapsControllerのテスト
  - `spec/controllers/sitemaps_controller_spec.rb`
  - XML形式確認
  - 公開記事含有確認
  - 下書き記事除外確認
  
- [ ] 6.2 FeedsControllerのテスト
  - `spec/controllers/feeds_controller_spec.rb`
  - RSS形式確認
  - Atom形式確認
  - 20件制限確認
  
- [ ] 6.3 統合テスト
  - `spec/requests/seo_features_spec.rb`
  - 各エンドポイントのアクセス確認

### Task 7: 動作確認・デプロイ
- [ ] 7.1 開発環境での動作確認
  - `/sitemap.xml`アクセス確認
  - `/feed.rss`アクセス確認
  - `/feed.atom`アクセス確認
  - `/robots.txt`アクセス確認
  - ブログページのフィードリンク確認
  
- [ ] 7.2 本番環境デプロイ
  - デプロイスクリプト実行
  - 本番環境での動作確認
  - Google Search Consoleへのsitemap登録


## 🔒 セキュリティ考慮事項

1. **XSS対策**: XMLビルダーは自動エスケープするが、記事タイトル・抜粋に注意
2. **情報漏洩防止**: 下書き記事を絶対に含めない（`.published`スコープ使用）
3. **DoS対策**: フィード取得は20件に制限
4. **robots.txt**: 管理画面へのクロールを明示的に禁止

## 📊 成功指標

1. **sitemap.xml**: Google Search Consoleで正常に認識される
2. **RSSフィード**: RSSリーダー（Feedly等）で購読可能
3. **クロール効率**: Search Consoleのクロール統計で改善確認
4. **購読者数**: RSSフィード購読者数の追跡（将来的にアナリティクス追加）

## 🚀 デプロイ手順

1. コード変更をコミット
2. テスト実行（`bundle exec rspec`）
3. 本番環境デプロイ（`./scripts/deploy.sh`）
4. 動作確認
   - https://yourdomain.com/sitemap.xml
   - https://yourdomain.com/feed.rss
   - https://yourdomain.com/feed.atom
   - https://yourdomain.com/robots.txt
5. Google Search Consoleにsitemap登録
   - Search Console → サイトマップ → 新しいサイトマップの追加
   - `sitemap.xml`を入力して送信

## 📚 参考資料

- [Sitemaps XML format](https://www.sitemaps.org/protocol.html)
- [RSS 2.0 Specification](https://www.rssboard.org/rss-specification)
- [Atom Syndication Format](https://datatracker.ietf.org/doc/html/rfc4287)
- [robots.txt Specification](https://www.robotstxt.org/robotstxt.html)
- [Google Search Console](https://search.google.com/search-console)

## 📝 備考

### 将来的な拡張
- **sitemap_generator gem**: 大規模サイトになった場合の導入検討
- **キャッシュ**: sitemap.xmlのキャッシュ（記事更新時に無効化）
- **画像sitemap**: 記事内画像のsitemap追加
- **動画sitemap**: 将来的に動画コンテンツ追加時
- **多言語対応**: hreflang属性の追加

### 既知の制限
- sitemap.xmlは50,000 URL、50MBまで（現状問題なし）
- RSSフィードは20件に制限（パフォーマンス考慮）

---

**作成日**: 2025-12-27  
**作成者**: Kiro  
**レビュー**: 未  
**承認**: 未
