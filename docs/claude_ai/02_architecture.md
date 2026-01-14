# アーキテクチャ仕様書

## システムアーキテクチャ概要

### アーキテクチャパターン
- **MVC + Service Layer Pattern**: Rails MVCにService層を追加した4層構造
- **RESTful API設計**: 公開API・内部API分離
- **Concern駆動設計**: 共通機能のモジュール化
- **Docker Compose**: 開発環境の完全コンテナ化

## レイヤー構成

### 1. プレゼンテーション層

#### フロントエンド
```
app/views/
├── layouts/
│   ├── application.html.erb    # メインレイアウト
│   ├── admin.html.erb          # 管理画面レイアウト
│   └── admin_auth.html.erb     # 認証画面専用
├── portfolio/                  # ポートフォリオページ
│   └── sections/              # 8つの動的セクション
├── blog/                      # ブログ機能
├── my_story/                  # My Storyページ
├── admin/                     # 管理画面（完全実装）
└── shared/                    # 共通パーツ
```

#### JavaScript/CSS構成
- **Stimulus Controllers**: モダンJavaScript
- **Tailwind CSS**: ユーティリティファーストCSS
- **Turbo**: SPA的なユーザー体験

### 2. コントローラー層

#### 名前空間構成
```ruby
# 管理画面
namespace :admin do
  resources :sections
  resources :articles
  resources :categories
  resources :tags
  resources :contacts
  resources :my_story_sections
  resource :site_settings
end

# 公開API
namespace :api do
  namespace :v1 do
    resources :articles
    resources :categories
    resources :tags
    resources :sections
  end
end
```

#### 主要コントローラー
- `ApplicationController`: 基底クラス、共通処理
- `Admin::BaseController`: 管理画面基底、認証必須
- `Api::V1::BaseController`: API基底、エラーハンドリング

### 3. サービス層（22クラス）

#### 記事管理サービス
```ruby
app/services/
├── article_content_manager.rb      # コンテンツ管理
├── article_meta_manager.rb         # SEO・メタデータ
├── article_publishing_manager.rb   # 公開状態管理
└── article_filter_service.rb       # フィルタリング
```

#### セクション管理サービス
```ruby
├── section_content_activation_service.rb  # アクティブ化
├── section_content_params_service.rb      # パラメータ処理
└── section_version_service.rb             # バージョン管理
```

#### My Storyサービス
```ruby
├── my_story_section_json_manager.rb       # JSON管理
├── my_story_section_position_manager.rb   # 並び順
└── my_story_section_ordering_service.rb   # 順序管理
```

#### サイト設定サービス
```ruby
├── site_setting_cache_manager.rb    # キャッシュ管理
├── site_setting_type_manager.rb     # 型管理
└── site_setting_value_manager.rb    # 値管理
```

#### SEO・メタデータサービス
```ruby
├── meta_tags_service.rb            # OGP・メタタグ生成
└── site_assets_service.rb          # アセット管理
```

### 4. モデル層

#### 主要モデルと責務
```ruby
# 認証・権限
AdminUser          # Devise認証、管理者アカウント

# コンテンツ管理
Article            # 記事（ブログ・Works共用）
Category           # カテゴリ（2階層対応）
Tag               # タグ
ArticleCategory    # 中間テーブル
ArticleTag        # 中間テーブル

# ポートフォリオ
Section           # セクション定義（8セクション）
SectionContent    # セクションコンテンツ（バージョン管理）

# その他
Contact           # お問い合わせ
MyStorySection    # My Story専用セクション
SiteSetting       # サイト設定
SlackNotification # Slack通知履歴
```

#### Concerns（共通機能）
```ruby
app/models/concerns/
├── publishable.rb    # 公開状態管理
├── positionable.rb   # 並び順管理
└── json_storable.rb  # JSON保存（実装予定）
```

### 5. データベース層

#### PostgreSQL 17-alpine特徴
- **ICUロケール**: 日本語ソート改善
- **JSONB活用**: 柔軟なコンテンツ保存
- **GINインデックス**: 高速検索
- **全文検索**: pg_search gem活用

#### 主要テーブル関係
```sql
admin_users (1) ----< (N) articles
articles (N) >----< (N) categories (through article_categories)
articles (N) >----< (N) tags (through article_tags)
sections (1) ----< (N) section_contents
categories (1) ----< (N) categories (self-referential)
```

## セキュリティアーキテクチャ

### 認証・認可
- **Devise**: 管理者認証
- **JWT**: API認証（Bearer Token）
- **Pundit**: きめ細かな認可制御

### セキュリティ対策
1. **管理画面URL難読化**: `/admin-secure-panel-miyakawa2449`
2. **Rack Attack**: レート制限（300req/5min）
3. **CORS設定**: API適切な制限
4. **CSRFトークン**: Rails標準
5. **セキュアヘッダー**: X-Frame-Options等

## パフォーマンスアーキテクチャ

### キャッシング戦略
```ruby
# Redis活用
- セッションストア
- Sidekiqジョブキュー
- API結果キャッシュ（5分）
- ポートフォリオセクション（30分）

# Solid Cache（Rails 8.1新機能）
- データベースベースのキャッシュ
- 自動失効管理
```

### バックグラウンド処理
```ruby
# Sidekiq 8.0
- メール送信
- AI分析（OpenAI API）
- 画像処理
- 定期バックアップ

# Solid Queue（Rails 8.1新機能）
- 軽量ジョブ処理
- データベース統合
```

### アセット最適化
- **Propshaft**: Rails 8.1新アセットパイプライン
- **Tailwind CSS**: PostCSSによる最適化
- **画像最適化**: Active Storage variant

## デプロイメントアーキテクチャ

### 開発環境（Docker Compose）
```yaml
services:
  web:       # Rails アプリケーション
  db:        # PostgreSQL 17-alpine
  redis:     # Redis 7-alpine
  sidekiq:   # バックグラウンドジョブ
```

### 本番環境（予定）
- **インフラ**: AWS Lightsail
- **Webサーバー**: Nginx + Puma
- **SSL**: Let's Encrypt
- **CDN**: CloudFront（将来）

## スケーラビリティ設計

### 水平スケーリング対応
- ステートレスアプリケーション設計
- Redisベースのセッション管理
- データベースコネクションプール最適化

### 垂直スケーリング対応
- N+1クエリ防止（includes使用）
- インデックス最適化
- クエリ最適化（Service層）

## 監視・運用

### 監視ツール
- **Sentry**: エラートラッキング
- **Rails Logger**: 詳細ログ
- **Sidekiq Web UI**: ジョブ監視

### 運用機能
- データベースバックアップ（自動）
- ログローテーション
- ヘルスチェックエンドポイント