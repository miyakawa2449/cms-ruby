# API仕様書

## API概要

### 基本情報
- **ベースURL**: `https://miyakawa.codes/api/v1`（本番）
- **フォーマット**: JSON
- **文字エンコーディング**: UTF-8
- **認証**: 公開APIは認証不要、内部APIはJWT認証

### レート制限
- **全体**: 300リクエスト/5分/IP
- **検索API**: 60リクエスト/分/IP
- **お問い合わせAPI**: 5リクエスト/分/IP

### 共通レスポンス形式

#### 成功時
```json
{
  "status": "success",
  "data": {
    // レスポンスデータ
  },
  "meta": {
    // ページネーション情報等
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

#### エラー時
```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ",
    "details": {
      // 詳細情報
    }
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

## 公開API（/api/v1）

### 1. 記事API

#### 記事一覧取得
```
GET /api/v1/articles
```

**パラメータ**
| パラメータ | 型 | 必須 | 説明 | デフォルト |
|-----------|-----|------|------|------------|
| page | integer | No | ページ番号 | 1 |
| per_page | integer | No | 1ページの件数（最大50） | 20 |
| status | string | No | 公開状態（published/draft） | published |
| category | string | No | カテゴリslug | - |
| tag | string | No | タグslug | - |
| q | string | No | 検索クエリ | - |
| sort | string | No | ソート（published_at,title,view_count） | published_at |
| order | string | No | 順序（asc/desc） | desc |

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "articles": [
      {
        "id": 1,
        "title": "Rails 8.1の新機能まとめ",
        "slug": "rails-8-1-new-features",
        "excerpt": "Rails 8.1で追加された新機能について解説します...",
        "content": "# Rails 8.1の新機能まとめ\n\n...",
        "status": "published",
        "published_at": "2024-12-15T09:00:00Z",
        "view_count": 1234,
        "reading_time": 5,
        "author": {
          "id": 1,
          "name": "宮川剛",
          "email": "admin@example.com"
        },
        "categories": [
          {
            "id": 1,
            "name": "Ruby on Rails",
            "slug": "ruby-on-rails",
            "color": "#cc0000"
          }
        ],
        "tags": [
          {
            "id": 1,
            "name": "Rails 8",
            "slug": "rails-8"
          }
        ],
        "thumbnail_url": "https://example.com/images/thumb.jpg",
        "meta": {
          "description": "Rails 8.1の新機能について詳しく解説",
          "keywords": ["Rails", "Ruby", "Web開発"]
        }
      }
    ]
  },
  "meta": {
    "current_page": 1,
    "next_page": 2,
    "prev_page": null,
    "total_pages": 10,
    "total_count": 195,
    "per_page": 20
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

#### 記事詳細取得
```
GET /api/v1/articles/:slug
```

**パラメータ**
- `slug`: 記事のスラッグ（URLパス）

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "article": {
      "id": 1,
      "title": "Rails 8.1の新機能まとめ",
      "slug": "rails-8-1-new-features",
      "content": "# Rails 8.1の新機能まとめ\n\n本文...",
      "content_html": "<h1>Rails 8.1の新機能まとめ</h1><p>本文...</p>",
      "excerpt": "Rails 8.1で追加された新機能について解説します...",
      "status": "published",
      "published_at": "2024-12-15T09:00:00Z",
      "updated_at": "2024-12-15T10:30:00Z",
      "view_count": 1234,
      "reading_time": 5,
      "work_type": null,
      "github_url": null,
      "demo_url": null,
      "tech_stack": null,
      "author": {
        "id": 1,
        "name": "宮川剛",
        "email": "admin@example.com",
        "avatar_url": "https://example.com/avatar.jpg"
      },
      "categories": [
        {
          "id": 1,
          "name": "Ruby on Rails",
          "slug": "ruby-on-rails",
          "description": "Ruby on Railsに関する記事",
          "color": "#cc0000",
          "parent": null
        }
      ],
      "tags": [
        {
          "id": 1,
          "name": "Rails 8",
          "slug": "rails-8"
        },
        {
          "id": 2,
          "name": "新機能",
          "slug": "new-features"
        }
      ],
      "thumbnail_url": "https://example.com/images/thumb.jpg",
      "og_image_url": "https://example.com/images/og.jpg",
      "meta": {
        "title": "Rails 8.1の新機能まとめ | Miyakawa Portfolio",
        "description": "Rails 8.1の新機能について詳しく解説",
        "keywords": ["Rails", "Ruby", "Web開発"],
        "canonical_url": "https://miyakawa.codes/blog/rails-8-1-new-features"
      },
      "related_articles": [
        {
          "id": 2,
          "title": "Rails 8.0からの移行ガイド",
          "slug": "rails-8-0-migration-guide",
          "excerpt": "Rails 8.0から8.1への移行手順..."
        }
      ]
    }
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

#### 記事検索
```
GET /api/v1/articles/search
```

**パラメータ**
| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| q | string | Yes | 検索クエリ |
| fields | array | No | 検索対象フィールド（title,content,excerpt） |
| highlight | boolean | No | ハイライト表示 |

### 2. カテゴリAPI

#### カテゴリ一覧取得
```
GET /api/v1/categories
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "categories": [
      {
        "id": 1,
        "name": "プログラミング",
        "slug": "programming",
        "description": "プログラミング全般",
        "icon": "code",
        "color": "#3b82f6",
        "position": 1,
        "article_count": 45,
        "parent_id": null,
        "children": [
          {
            "id": 2,
            "name": "Ruby on Rails",
            "slug": "ruby-on-rails",
            "article_count": 23,
            "parent_id": 1
          }
        ]
      }
    ]
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

#### カテゴリ別記事取得
```
GET /api/v1/categories/:id/articles
```

### 3. タグAPI

#### タグ一覧取得
```
GET /api/v1/tags
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "tags": [
      {
        "id": 1,
        "name": "Rails 8",
        "slug": "rails-8",
        "article_count": 15
      },
      {
        "id": 2,
        "name": "Docker",
        "slug": "docker",
        "article_count": 12
      }
    ]
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

#### タグ別記事取得
```
GET /api/v1/tags/:id/articles
```

### 4. セクションAPI

#### セクション一覧取得
```
GET /api/v1/sections
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "sections": [
      {
        "id": 1,
        "name": "hero",
        "display_name": "ヒーローセクション",
        "position": 1,
        "is_visible": true,
        "content": {
          "main_title": "宮川剛",
          "sub_title": "シニアエンジニア / AIエンジニア",
          "cta_button_text": "お問い合わせ",
          "hero_image_url": "https://example.com/hero.jpg"
        }
      },
      {
        "id": 2,
        "name": "about",
        "display_name": "About",
        "position": 2,
        "is_visible": true,
        "content": {
          "profile_text": "20年以上の経験を持つシニアエンジニア...",
          "skills": {
            "backend": ["Ruby", "Rails", "PostgreSQL"],
            "frontend": ["React", "Vue.js", "TypeScript"],
            "infrastructure": ["AWS", "Docker", "Kubernetes"]
          },
          "profile_image_url": "https://example.com/profile.jpg"
        }
      }
    ]
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

#### セクション詳細取得
```
GET /api/v1/sections/:name
```

### 5. お問い合わせAPI

#### お問い合わせ送信
```
POST /api/v1/contacts
```

**リクエストボディ**
```json
{
  "contact": {
    "name": "山田太郎",
    "email": "yamada@example.com",
    "subject": "プロジェクトのご相談",
    "message": "新規プロジェクトについてご相談があります...",
    "recaptcha_token": "reCAPTCHA_TOKEN"
  }
}
```

**レスポンス例**
```json
{
  "status": "success",
  "data": {
    "message": "お問い合わせを受け付けました。ありがとうございます。"
  },
  "timestamp": "2024-12-16T10:30:00Z"
}
```

## 内部管理API（/api/internal）

### 認証

#### JWT取得
```
POST /api/internal/auth/login
```

**リクエストボディ**
```json
{
  "email": "admin@example.com",
  "password": "secure_password"
}
```

**レスポンス**
```json
{
  "status": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "expires_at": "2024-12-17T10:30:00Z",
    "user": {
      "id": 1,
      "email": "admin@example.com",
      "name": "管理者"
    }
  }
}
```

### 認証ヘッダー
```
Authorization: Bearer YOUR_JWT_TOKEN
```

### 記事管理API

#### 記事作成
```
POST /api/internal/articles
```

#### 記事更新
```
PATCH /api/internal/articles/:id
```

#### 記事削除
```
DELETE /api/internal/articles/:id
```

#### 一括操作
```
PATCH /api/internal/articles/bulk
```

**リクエストボディ**
```json
{
  "article_ids": [1, 2, 3],
  "operation": "publish",
  "options": {
    "published_at": "2024-12-16T10:00:00Z"
  }
}
```

## エラーコード

### HTTPステータスコード
- `200 OK`: 成功
- `201 Created`: リソース作成成功
- `400 Bad Request`: リクエスト不正
- `401 Unauthorized`: 認証エラー
- `403 Forbidden`: アクセス拒否
- `404 Not Found`: リソースが見つからない
- `422 Unprocessable Entity`: バリデーションエラー
- `429 Too Many Requests`: レート制限
- `500 Internal Server Error`: サーバーエラー

### エラーコード一覧
| コード | 説明 |
|--------|------|
| VALIDATION_ERROR | バリデーションエラー |
| AUTHENTICATION_REQUIRED | 認証が必要 |
| INVALID_TOKEN | 無効なトークン |
| TOKEN_EXPIRED | トークンの有効期限切れ |
| RATE_LIMIT_EXCEEDED | レート制限超過 |
| RESOURCE_NOT_FOUND | リソースが見つからない |
| PERMISSION_DENIED | 権限がない |
| INVALID_PARAMETER | 無効なパラメータ |

## SDK使用例

### JavaScript/TypeScript
```typescript
// APIクライアント
class PortfolioAPI {
  private baseURL = 'https://miyakawa.codes/api/v1';
  
  async getArticles(params?: ArticleParams): Promise<ArticleResponse> {
    const queryString = new URLSearchParams(params).toString();
    const response = await fetch(`${this.baseURL}/articles?${queryString}`);
    return response.json();
  }
  
  async getArticle(slug: string): Promise<ArticleDetailResponse> {
    const response = await fetch(`${this.baseURL}/articles/${slug}`);
    if (!response.ok) {
      throw new Error(`Article not found: ${slug}`);
    }
    return response.json();
  }
}

// 使用例
const api = new PortfolioAPI();
const articles = await api.getArticles({ 
  category: 'ruby-on-rails',
  per_page: 10 
});
```

### Ruby
```ruby
require 'net/http'
require 'json'

class PortfolioAPIClient
  BASE_URL = 'https://miyakawa.codes/api/v1'
  
  def get_articles(params = {})
    uri = URI("#{BASE_URL}/articles")
    uri.query = URI.encode_www_form(params) if params.any?
    
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)
  end
  
  def get_article(slug)
    uri = URI("#{BASE_URL}/articles/#{slug}")
    response = Net::HTTP.get_response(uri)
    
    raise "Article not found" unless response.code == '200'
    JSON.parse(response.body)
  end
end

# 使用例
client = PortfolioAPIClient.new
articles = client.get_articles(category: 'ruby-on-rails', per_page: 10)
```

## Webhook

### Slack通知Webhook
お問い合わせ受信時にSlackへ通知を送信

**Webhook URL設定**
管理画面のサイト設定から設定

**ペイロード例**
```json
{
  "text": "新しいお問い合わせがありました",
  "attachments": [
    {
      "color": "good",
      "fields": [
        {
          "title": "お名前",
          "value": "山田太郎",
          "short": true
        },
        {
          "title": "メールアドレス",
          "value": "yamada@example.com",
          "short": true
        },
        {
          "title": "件名",
          "value": "プロジェクトのご相談",
          "short": false
        },
        {
          "title": "メッセージ",
          "value": "新規プロジェクトについてご相談があります...",
          "short": false
        }
      ],
      "footer": "Portfolio CMS",
      "ts": 1702728600
    }
  ]
}
```