# API実装計画詳細書

## 概要
Phase 4（Sprint 6-7）でのAPI機能実装の詳細計画。既存機能を維持しながら段階的にAPI化を進める。

## Sprint 6: 公開API実装（2週間）

### Week 1: API基盤構築

#### 1日目: Rails API設定・基盤構築
```bash
# Gemfile追加
gem 'active_model_serializers', '~> 0.10.0'
gem 'rack-attack'
gem 'rack-cors'
```

**作業項目:**
- Rails API機能有効化
- CORS設定（config/application.rb）
- レート制限設定（Rack::Attack）
- API バージョニング構造作成

#### 2日目: ルーティング・コントローラー基盤
```ruby
# config/routes.rb
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
  end
end
```

**作業項目:**
- API::V1::BaseController作成
- 共通エラーハンドリング実装
- JSON レスポンス形式統一

#### 3日目: シリアライザー実装
```ruby
# app/serializers/api/v1/article_serializer.rb
class Api::V1::ArticleSerializer < ActiveModel::Serializer
  attributes :id, :title, :slug, :excerpt, :published_at, 
             :reading_time, :view_count, :updated_at
  
  belongs_to :user, key: :author
  has_many :categories
  has_many :tags
  has_one :featured_image
end
```

**作業項目:**
- 記事・カテゴリ・タグシリアライザー
- ページネーションメタデータ
- 画像URL・ALT属性対応

### Week 2: エンドポイント実装

#### 4-5日目: ブログ記事API
**エンドポイント実装:**
- `GET /api/v1/articles` - 一覧・検索・フィルタ
- `GET /api/v1/articles/:slug` - 詳細・関連記事
- `GET /api/v1/categories` - カテゴリ階層
- `GET /api/v1/tags` - タグ一覧

**機能:**
- 検索クエリ対応（title、content）
- フィルタ（category、tag、status）
- ソート（published_at、view_count）
- ページネーション（kaminari）

#### 6-7日目: ポートフォリオ・ユーティリティAPI
**エンドポイント実装:**
- `GET /api/v1/portfolio` - 全セクション配信
- `GET /api/v1/portfolio/works/:id` - 作品詳細
- `POST /api/v1/contacts` - お問い合わせ（reCAPTCHA）
- `GET /api/v1/sitemap` - サイトマップJSON
- `GET /api/v1/feed.rss` - RSS配信

**機能:**
- JSONBコンテンツの動的配信
- reCAPTCHA検証・Slack通知
- 動的サイトマップ生成

#### 8-10日目: テスト・ドキュメント
**テスト実装:**
```ruby
# spec/requests/api/v1/articles_spec.rb
RSpec.describe 'Api::V1::Articles', type: :request do
  describe 'GET /api/v1/articles' do
    it '記事一覧を取得できる' do
      create_list(:article, 15, :published)
      get '/api/v1/articles'
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data'].size).to eq(10)
      expect(json['meta']['pagination']).to be_present
    end
  end
end
```

**作業項目:**
- RSpec API テスト実装
- Postmanコレクション作成
- API ドキュメント基本版

## Sprint 7: 内部管理API実装（2週間）

### Week 1: 認証・記事管理API

#### 1日目: JWT認証実装
```ruby
# app/controllers/api/internal/auth_controller.rb
class Api::Internal::AuthController < Api::Internal::BaseController
  def login
    user = User.find_by(email: params[:email])
    if user&.valid_password?(params[:password])
      token = generate_jwt(user)
      render json: { token: token, user: UserSerializer.new(user) }
    else
      render_error('INVALID_CREDENTIALS', 'ログイン情報が無効です', 401)
    end
  end
end
```

**作業項目:**
- JWT gem導入・設定
- Devise統合・トークン生成
- ロールベースアクセス制御

#### 2-3日目: 記事管理API
**エンドポイント実装:**
- `POST /api/internal/articles` - 記事作成
- `PATCH /api/internal/articles/:id` - 記事更新
- `DELETE /api/internal/articles/:id` - 記事削除
- `PATCH /api/internal/articles/bulk` - 一括操作

**機能:**
- リアルタイム自動保存
- リビジョン管理
- 下書き・公開・予約投稿
- 一括ステータス変更

#### 4-5日目: AI機能API
**エンドポイント実装:**
- `POST /api/internal/ai/analyze` - AI分析実行
- `GET /api/internal/ai/analyze/:article_id` - 分析結果取得

**機能:**
- OpenAI API統合（GPT-4）
- Sidekiq非同期処理
- 進捗状況リアルタイム表示
- 予算監視・使用量統計

### Week 2: メディア管理・フロントエンド統合

#### 6-7日目: メディア管理API
**エンドポイント実装:**
- `POST /api/internal/media` - ファイルアップロード
- `GET /api/internal/media` - メディア一覧・検索
- `PUT /api/internal/media/:id` - メタデータ更新

**機能:**
- ドラッグ&ドロップ対応
- WebP自動変換・進捗表示
- 使用状況追跡・未使用ファイル検知
- Alt属性・キャプション管理

#### 8-9日目: フロントエンド統合
**統合作業:**
- 検索機能API化（blog_top_prototype.html）
- お問い合わせフォーム非同期化
- 管理画面リアルタイム機能（自動保存、進捗表示）

#### 10日目: API統計・ログ機能
**実装内容:**
- API使用状況ダッシュボード
- エラーログ・パフォーマンス監視
- 管理画面での統計表示

## パフォーマンス最適化

### キャッシング戦略
```ruby
# config/application.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 5.minutes
}

# app/controllers/api/v1/articles_controller.rb
def index
  cache_key = ['api/v1/articles', params.to_h].flatten
  @articles = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
    Article.published.includes(:categories, :tags).page(params[:page])
  end
end
```

### レート制限設定
```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/ip', limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?('/api/')
end

Rack::Attack.throttle('api/contacts', limit: 5, period: 1.minute) do |req|
  req.ip if req.path == '/api/v1/contacts' && req.post?
end
```

## セキュリティ考慮事項

### 入力検証
```ruby
# app/controllers/api/v1/contacts_controller.rb
def create
  @contact = Contact.new(contact_params)
  
  # reCAPTCHA検証
  unless verify_recaptcha(model: @contact)
    render_error('RECAPTCHA_FAILED', 'reCAPTCHA認証に失敗しました', 400)
    return
  end
  
  if @contact.save
    ContactNotificationJob.perform_later(@contact)
    render json: { message: 'お問い合わせを受け付けました' }, status: :created
  else
    render_validation_errors(@contact)
  end
end
```

### CORS設定
```ruby
# config/application.rb
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://example.test', 'localhost:3000'
    resource '/api/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: false
  end
end
```

## 監視・ログ

### API使用状況監視
```ruby
# app/controllers/api/v1/base_controller.rb
after_action :log_api_usage

private

def log_api_usage
  ApiUsageLog.create(
    endpoint: "#{request.method} #{request.path}",
    ip_address: request.ip,
    user_agent: request.user_agent,
    response_time: response.headers['X-Runtime'].to_f,
    status_code: response.status
  )
end
```

### エラー監視
```ruby
# config/application.rb
config.exceptions_app = ->(env) {
  Api::ErrorsController.action(:show).call(env)
}

# app/controllers/api/errors_controller.rb
class Api::ErrorsController < Api::V1::BaseController
  def show
    error_code = request.env['action_dispatch.exception']&.class&.name
    
    render json: {
      status: 'error',
      error: {
        code: error_code,
        message: 'システムエラーが発生しました'
      }
    }, status: 500
  end
end
```

## デプロイ・運用

### 環境別設定
```ruby
# config/environments/production.rb
config.force_ssl = true
config.api.only = false  # HTML responseも必要
config.active_job.queue_adapter = :sidekiq

# API用の専用設定
config.middleware.use Rack::Attack
config.log_level = :info
```

### CI/CD統合
```yaml
# .github/workflows/api_test.yml
name: API Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.0
      - name: Run API Tests
        run: |
          bundle install
          bundle exec rspec spec/requests/api/
```

## 成功指標

### 技術指標
- API応答時間: 平均200ms以下
- 可用性: 99.9%
- エラー率: 1%以下

### 機能指標
- 検索レスポンス速度: 500ms以下
- ファイルアップロード成功率: 98%以上
- AI分析精度: 満足度80%以上

### 運用指標
- API ドキュメント完成度: 100%
- テストカバレッジ: 90%以上
- セキュリティ監査: 全項目クリア