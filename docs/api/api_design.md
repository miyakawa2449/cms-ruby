# API設計書

## 概要
ポートフォリオサイトのREST API設計。将来的な拡張性と実務での再利用を考慮した設計。

## API設計方針

### 基本原則
1. **RESTful設計**: リソース指向・HTTP動詞の適切な使用
2. **バージョニング**: `/api/v1/` でバージョン管理
3. **認証**: 公開APIと認証必須APIの明確な分離
4. **レスポンス形式**: JSON（一貫性のある構造）
5. **エラーハンドリング**: 適切なHTTPステータスコードとエラーメッセージ

### レスポンス構造
```json
// 成功時
{
  "status": "success",
  "data": { ... },
  "meta": {
    "timestamp": "2024-11-28T10:00:00Z",
    "version": "1.0"
  }
}

// エラー時
{
  "status": "error",
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "指定された記事が見つかりません",
    "details": { ... }
  }
}

// ページネーション付き
{
  "status": "success",
  "data": [ ... ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 10,
      "total_count": 98,
      "per_page": 10
    }
  }
}
```

## 1. ブログ記事API（公開API）

### エンドポイント一覧

#### 記事一覧取得
```
GET /api/v1/articles
```

**パラメータ**
- `page` (integer): ページ番号（デフォルト: 1）
- `per_page` (integer): 1ページあたりの件数（デフォルト: 10、最大: 50）
- `category` (string): カテゴリスラッグ
- `tag` (string): タグスラッグ
- `search` (string): 検索キーワード
- `sort` (string): ソート順（published_at_desc, published_at_asc, view_count）

**レスポンス例**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "title": "Ruby on Rails 8.0の新機能",
      "slug": "rails-8-new-features",
      "excerpt": "Rails 8.0で追加された新機能について...",
      "published_at": "2024-11-28T09:00:00Z",
      "reading_time": 5,
      "view_count": 150,
      "author": {
        "name": "宮川剛",
        "avatar_url": "https://..."
      },
      "categories": [
        {
          "id": 1,
          "name": "技術",
          "slug": "tech",
          "parent": null
        }
      ],
      "tags": [
        {
          "id": 1,
          "name": "Rails",
          "slug": "rails"
        }
      ],
      "featured_image": {
        "url": "https://...",
        "alt": "Rails 8.0",
        "width": 1200,
        "height": 630
      }
    }
  ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 48,
      "per_page": 10
    }
  }
}
```

#### 記事詳細取得
```
GET /api/v1/articles/:slug
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "title": "Ruby on Rails 8.0の新機能",
    "slug": "rails-8-new-features",
    "content": "# Rails 8.0の新機能\n\n本記事では...",
    "content_html": "<h1>Rails 8.0の新機能</h1><p>本記事では...</p>",
    "excerpt": "Rails 8.0で追加された新機能について...",
    "published_at": "2024-11-28T09:00:00Z",
    "updated_at": "2024-11-28T10:30:00Z",
    "reading_time": 5,
    "view_count": 150,
    "author": {
      "name": "宮川剛",
      "avatar_url": "https://...",
      "bio": "シニアエンジニア"
    },
    "categories": [
      {
        "id": 1,
        "name": "技術",
        "slug": "tech",
        "parent": null,
        "full_path": "tech"
      }
    ],
    "tags": [
      {
        "id": 1,
        "name": "Rails",
        "slug": "rails"
      }
    ],
    "featured_image": {
      "url": "https://...",
      "alt": "Rails 8.0",
      "width": 1200,
      "height": 630
    },
    "seo": {
      "title": "Ruby on Rails 8.0の新機能 | 宮川剛のブログ",
      "description": "Rails 8.0で追加された新機能について詳しく解説",
      "keywords": ["Rails", "Ruby", "Web開発"],
      "og_image": "https://..."
    },
    "related_articles": [
      {
        "id": 2,
        "title": "Rails 7からの移行ガイド",
        "slug": "rails-7-to-8-migration",
        "excerpt": "Rails 7から8への移行手順..."
      }
    ]
  }
}
```

#### カテゴリ一覧取得
```
GET /api/v1/categories
```

**レスポンス例**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "name": "技術",
      "slug": "tech",
      "description": "技術関連の記事",
      "article_count": 25,
      "icon": "code",
      "color": "#3B82F6",
      "children": [
        {
          "id": 2,
          "name": "Ruby",
          "slug": "ruby",
          "parent_id": 1,
          "article_count": 10
        }
      ]
    }
  ]
}
```

#### タグ一覧取得
```
GET /api/v1/tags
```

**レスポンス例**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "name": "Rails",
      "slug": "rails",
      "article_count": 15
    },
    {
      "id": 2,
      "name": "PostgreSQL",
      "slug": "postgresql",
      "article_count": 8
    }
  ]
}
```

## 2. ポートフォリオAPI（公開API）

### エンドポイント一覧

#### ポートフォリオデータ取得
```
GET /api/v1/portfolio
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "hero": {
      "title": "宮川剛のポートフォリオ",
      "subtitle": "要件定義から実装まで一人でできるシニアエンジニア",
      "cta_text": "お問い合わせ",
      "cta_url": "/contact",
      "background_image": "https://..."
    },
    "about": {
      "profile_image": "https://...",
      "description": "20年以上の経験を持つシニアエンジニア...",
      "skills": [
        {
          "category": "Backend",
          "items": ["Ruby", "Rails", "PostgreSQL"]
        },
        {
          "category": "Frontend",
          "items": ["JavaScript", "React", "Tailwind CSS"]
        }
      ],
      "experience_years": 20
    },
    "services": [
      {
        "id": 1,
        "title": "システム開発",
        "description": "要件定義から実装まで一貫して対応",
        "icon": "code"
      }
    ],
    "my_story": {
      "summary": "パソコンスクール講師からSE/PMを経て...",
      "phases": [
        {
          "period": "1994-2005",
          "title": "パソコンスクール講師時代",
          "description": "人材育成・プロジェクト管理基礎力の形成"
        }
      ],
      "detail_url": "/my-story"
    },
    "works": [
      {
        "id": 1,
        "title": "ECサイト構築",
        "description": "大規模ECサイトの設計・開発",
        "image": "https://...",
        "technologies": ["Rails", "PostgreSQL", "Redis"],
        "url": "https://example.com",
        "featured": true
      }
    ]
  }
}
```

#### 作品詳細取得
```
GET /api/v1/portfolio/works/:id
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "title": "ECサイト構築",
    "description": "大規模ECサイトの設計・開発",
    "long_description": "このプロジェクトでは...",
    "images": [
      {
        "url": "https://...",
        "alt": "トップページ",
        "caption": "レスポンシブデザイン対応"
      }
    ],
    "technologies": ["Rails", "PostgreSQL", "Redis", "Docker"],
    "role": "リードエンジニア",
    "duration": "6ヶ月",
    "team_size": 5,
    "url": "https://example.com",
    "github_url": "https://github.com/...",
    "challenges": [
      "高トラフィック対応",
      "決済システム統合"
    ],
    "achievements": [
      "応答時間50%削減",
      "可用性99.9%達成"
    ]
  }
}
```

## 3. お問い合わせAPI（公開API + reCAPTCHA）

### エンドポイント

#### お問い合わせ送信
```
POST /api/v1/contacts
```

**リクエストボディ**
```json
{
  "name": "山田太郎",
  "email": "yamada@example.com",
  "subject": "開発のご相談",
  "message": "新規プロジェクトについてご相談があります...",
  "recaptcha_token": "..."
}
```

**バリデーション**
- name: 必須、最大100文字
- email: 必須、有効なメールアドレス
- subject: 必須、最大255文字
- message: 必須、最大5000文字
- recaptcha_token: 必須（スパム対策）

**レスポンス例（成功）**
```json
{
  "status": "success",
  "data": {
    "id": 123,
    "message": "お問い合わせを受け付けました。返信まで1-2営業日お待ちください。"
  }
}
```

**レスポンス例（エラー）**
```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力内容に誤りがあります",
    "details": {
      "email": ["有効なメールアドレスを入力してください"],
      "message": ["メッセージは必須です"]
    }
  }
}
```

## 4. 自動生成API

### サイトマップAPI
```
GET /api/v1/sitemap
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "pages": [
      {
        "url": "https://example.test/",
        "lastmod": "2024-11-28T10:00:00Z",
        "priority": 1.0
      },
      {
        "url": "https://example.test/blog",
        "lastmod": "2024-11-28T09:00:00Z",
        "priority": 0.8
      }
    ],
    "articles": [
      {
        "url": "https://example.test/blog/rails-8-new-features",
        "lastmod": "2024-11-28T09:00:00Z",
        "priority": 0.6
      }
    ],
    "categories": [
      {
        "url": "https://example.test/blog/category/tech",
        "lastmod": "2024-11-27T12:00:00Z",
        "priority": 0.5
      }
    ]
  }
}
```

### RSSフィードAPI
```
GET /api/v1/feed
GET /api/v1/feed.rss (RSS 2.0形式)
GET /api/v1/feed.atom (Atom形式)
```

**JSONレスポンス例**
```json
{
  "status": "success",
  "data": {
    "title": "宮川剛のブログ",
    "description": "技術発信・ポートフォリオサイト",
    "link": "https://example.test/blog",
    "language": "ja",
    "last_build_date": "2024-11-28T10:00:00Z",
    "items": [
      {
        "title": "Ruby on Rails 8.0の新機能",
        "link": "https://example.test/blog/rails-8-new-features",
        "description": "Rails 8.0で追加された新機能について...",
        "pub_date": "2024-11-28T09:00:00Z",
        "guid": "https://example.test/blog/rails-8-new-features",
        "categories": ["技術", "Rails"]
      }
    ]
  }
}
```

## 5. 内部管理API（認証必須）

### 認証方式
- JWT（JSON Web Token）を使用
- Bearerトークンとして送信
- 有効期限: 24時間

### エンドポイント例

#### ログイン
```
POST /api/internal/auth/login
```

#### 記事管理
```
GET    /api/internal/articles        # 管理画面用記事一覧（下書き含む）
POST   /api/internal/articles        # 記事作成
PATCH  /api/internal/articles/:id    # 記事更新
DELETE /api/internal/articles/:id    # 記事削除
```

#### AI分析実行
```
POST /api/internal/ai/analyze
```

**リクエスト**
```json
{
  "article_id": 1,
  "functions": ["summary", "keywords", "seo_score"]
}
```

#### メディアアップロード
```
POST /api/internal/media
Content-Type: multipart/form-data
```

## 実装のポイント

### 1. コントローラー構造
```ruby
app/controllers/
├── api/
│   ├── v1/
│   │   ├── base_controller.rb      # 共通処理
│   │   ├── articles_controller.rb
│   │   ├── categories_controller.rb
│   │   ├── tags_controller.rb
│   │   ├── portfolio_controller.rb
│   │   ├── contacts_controller.rb
│   │   ├── sitemap_controller.rb
│   │   └── feed_controller.rb
│   └── internal/
│       ├── base_controller.rb      # 認証処理
│       ├── auth_controller.rb
│       ├── articles_controller.rb
│       └── ai_controller.rb
```

### 2. ルーティング設定
```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :articles, only: [:index, :show], param: :slug
      resources :categories, only: [:index, :show], param: :slug
      resources :tags, only: [:index, :show], param: :slug
      
      resource :portfolio, only: [:show] do
        resources :works, only: [:show]
      end
      
      resources :contacts, only: [:create]
      
      get 'sitemap', to: 'sitemap#index'
      get 'feed', to: 'feed#index'
      get 'feed.:format', to: 'feed#index'
    end
    
    namespace :internal do
      post 'auth/login', to: 'auth#login'
      
      resources :articles
      post 'ai/analyze', to: 'ai#analyze'
      resources :media, only: [:create]
    end
  end
end
```

### 3. シリアライザー
```ruby
# Active Model Serializersを使用
class Api::V1::ArticleSerializer < ActiveModel::Serializer
  attributes :id, :title, :slug, :excerpt, :published_at,
             :reading_time, :view_count
  
  belongs_to :author
  has_many :categories
  has_many :tags
  has_one :featured_image
  
  def author
    {
      name: object.user.name,
      avatar_url: object.user.avatar_url
    }
  end
end
```

### 4. エラーハンドリング
```ruby
module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound do |e|
        render_error('RESOURCE_NOT_FOUND', 'リソースが見つかりません', 404)
      end
      
      rescue_from ActionController::ParameterMissing do |e|
        render_error('PARAMETER_MISSING', "必須パラメータがありません: #{e.param}", 400)
      end
      
      private
      
      def render_error(code, message, status)
        render json: {
          status: 'error',
          error: {
            code: code,
            message: message
          }
        }, status: status
      end
    end
  end
end
```

### 5. キャッシング戦略
```ruby
class Api::V1::ArticlesController < Api::V1::BaseController
  def index
    @articles = Rails.cache.fetch(['api/v1/articles', params], expires_in: 5.minutes) do
      Article.published
             .includes(:user, :categories, :tags, :featured_image)
             .page(params[:page])
             .per(params[:per_page] || 10)
    end
    
    render json: @articles, meta: pagination_meta(@articles)
  end
end
```

### 6. レート制限
```ruby
# Rackミドルウェアで実装
# config/application.rb
config.middleware.use Rack::Attack

# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?('/api/')
end

Rack::Attack.throttle('api/aggressive', limit: 5, period: 1.minute) do |req|
  req.ip if req.path == '/api/v1/contacts' && req.post?
end
```

## テスト戦略

### RSpec例
```ruby
RSpec.describe 'Api::V1::Articles', type: :request do
  describe 'GET /api/v1/articles' do
    let!(:articles) { create_list(:article, 15, :published) }
    
    it '記事一覧を取得できる' do
      get '/api/v1/articles'
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('success')
      expect(json['data'].size).to eq(10) # デフォルトper_page
      expect(json['meta']['pagination']).to be_present
    end
    
    it 'カテゴリでフィルタできる' do
      category = create(:category, slug: 'tech')
      tech_articles = create_list(:article, 3, :published, categories: [category])
      
      get '/api/v1/articles', params: { category: 'tech' }
      
      json = JSON.parse(response.body)
      expect(json['data'].size).to eq(3)
    end
  end
end
```

## セキュリティ考慮事項

1. **CORS設定**: 適切なオリジンのみ許可
2. **APIキー管理**: 内部APIは認証必須
3. **レート制限**: DDoS対策
4. **入力検証**: SQLインジェクション対策
5. **出力フィルタリング**: XSS対策

## ドキュメント生成

### OpenAPI (Swagger) 仕様
```yaml
openapi: 3.0.0
info:
  title: ポートフォリオサイトAPI
  version: 1.0.0
  description: 宮川剛のポートフォリオサイトAPI

paths:
  /api/v1/articles:
    get:
      summary: 記事一覧取得
      tags:
        - Articles
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: per_page
          in: query
          schema:
            type: integer
            default: 10
            maximum: 50
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ArticlesResponse'
```

## メリット

1. **基礎練習＋資産化**: 実務でも使える汎用的なAPI
2. **スマホアプリ対応**: 将来的なネイティブアプリ開発が可能
3. **外部連携**: 他サービスとの連携が容易
4. **SEO向上**: サイトマップ・RSS配信でクローラビリティ向上
5. **開発効率**: フロントエンドとバックエンドの分離開発が可能