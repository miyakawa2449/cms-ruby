# ルーティング＆コントローラー仕様書

## ルーティング概要

### ルーティング構成
```ruby
Rails.application.routes.draw do
  # Devise認証
  devise_for :admin_users, path: 'admin_auth', controllers: {
    sessions: 'admin_users/sessions'
  }
  
  # 管理画面（セキュリティ強化URL）
  namespace :admin, path: 'admin-secure-panel-miyakawa2449' do
    root 'dashboard#index'
    resources :sections
    resources :articles
    resources :categories
    resources :tags
    resources :contacts
    resources :my_story_sections do
      member { patch :move }
    end
    resource :site_settings, only: [:edit, :update]
  end
  
  # 公開API
  namespace :api do
    namespace :v1 do
      resources :articles, param: :slug, only: [:index, :show] do
        collection { get :search }
      end
      resources :categories, only: [:index, :show] do
        member { get :articles }
      end
      resources :tags, only: [:index, :show] do
        member { get :articles }
      end
      resources :sections, param: :name, only: [:index, :show]
    end
  end
  
  # フロントエンド
  root "portfolio#index"
  get "blog", to: "blog#index"
  get "blog/:slug", to: "blog#show", as: :blog_article
  get "blog/category/:slug", to: "blog#category", as: :blog_category
  get "blog/tag/:slug", to: "blog#tag", as: :blog_tag
  get "my-story", to: "my_story#index"
  resources :contacts, only: [:create]
  
  # PWA
  get "service-worker", to: "pwa#service_worker"
  get "manifest", to: "pwa#manifest"
end
```

## コントローラー詳細

### 基底コントローラー

#### ApplicationController
```ruby
class ApplicationController < ActionController::Base
  # 基本設定
  protect_from_forgery with: :exception
  
  # 共通メソッド
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  private
  
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
```

#### Admin::BaseController
```ruby
class Admin::BaseController < ApplicationController
  # 認証必須
  before_action :authenticate_admin_user!
  
  # レイアウト指定
  layout 'admin'
  
  # 共通機能
  helper_method :current_section
  
  private
  
  def current_section
    controller_name
  end
end
```

### 管理画面コントローラー

#### Admin::ArticlesController
**主要アクション**:
- `index`: 記事一覧（ページネーション、フィルタリング対応）
- `new/create`: 新規作成（下書き保存対応）
- `edit/update`: 編集（リアルタイム保存）
- `destroy`: 論理削除
- `publish`: 公開処理（非同期）
- `archive`: アーカイブ処理

**特徴**:
- Strong Parameters使用
- Service層への委譲（ArticleContentManager等）
- 一括操作対応（bulk_update）

#### Admin::CategoriesController
**主要アクション**:
- `index`: カテゴリ一覧（階層表示）
- `new/create`: 新規作成（親カテゴリ選択可）
- `edit/update`: 編集（記事数自動更新）
- `destroy`: 削除（子カテゴリチェック）
- `reorder`: 並び順変更（Ajax）

**特徴**:
- 階層構造の管理
- ドラッグ&ドロップ並び替え
- 記事数の自動カウント

#### Admin::SectionsController
**主要アクション**:
- `index`: セクション一覧（8セクション固定）
- `edit/update`: コンテンツ編集
- `preview`: プレビュー表示
- `activate`: バージョンアクティブ化
- `revert`: 前バージョンに戻す

**特徴**:
- JSONBコンテンツ管理
- バージョン管理機能
- Active Storage統合（画像アップロード）

#### Admin::ContactsController
**主要アクション**:
- `index`: お問い合わせ一覧
- `show`: 詳細表示
- `update_status`: ステータス更新
- `assign`: 担当者アサイン
- `reply`: 返信送信

**特徴**:
- ステータス管理（unread/read/replied/archived）
- Slack通知連携
- スパムフィルタリング

### 公開APIコントローラー

#### Api::V1::BaseController
```ruby
class Api::V1::BaseController < ActionController::API
  # 共通設定
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  # エラーハンドリング
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  
  # レート制限
  before_action :check_rate_limit
  
  private
  
  def render_json_response(data, status = :ok)
    render json: {
      status: 'success',
      data: data,
      timestamp: Time.current
    }, status: status
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: {
      status: 'error',
      message: message,
      timestamp: Time.current
    }, status: status
  end
end
```

#### Api::V1::ArticlesController
**エンドポイント**:
- `GET /api/v1/articles` - 記事一覧
- `GET /api/v1/articles/:slug` - 記事詳細
- `GET /api/v1/articles/search` - 記事検索

**レスポンス形式**:
```json
{
  "status": "success",
  "data": {
    "articles": [...],
    "meta": {
      "current_page": 1,
      "total_pages": 10,
      "total_count": 100
    }
  }
}
```

#### Api::V1::SectionsController
**エンドポイント**:
- `GET /api/v1/sections` - 全セクション取得
- `GET /api/v1/sections/:name` - 特定セクション取得

**特徴**:
- アクティブなコンテンツのみ返却
- キャッシュ対応（30分）
- 画像URL含む完全データ

### フロントエンドコントローラー

#### PortfolioController
**アクション**:
- `index`: トップページ表示

**特徴**:
- 8セクションの動的読み込み
- セクション毎の部分キャッシュ
- レスポンシブ対応

#### BlogController
**アクション**:
- `index`: ブログ一覧
- `show`: 記事詳細
- `category`: カテゴリ別一覧
- `tag`: タグ別一覧

**特徴**:
- SEOフレンドリーURL（slug使用）
- ページネーション（Kaminari）
- 関連記事表示
- メタタグ自動生成

#### MyStoryController
**アクション**:
- `index`: My Story表示

**特徴**:
- 3フェーズのキャリアタイムライン
- スクロールアニメーション連携
- 動的セクション読み込み

#### ContactsController
**アクション**:
- `create`: お問い合わせ送信

**特徴**:
- Ajax非同期送信
- reCAPTCHA検証
- 自動サニタイゼーション
- Slack通知送信

## コントローラー共通機能

### Concerns

#### Paginatable
```ruby
module Paginatable
  extend ActiveSupport::Concern
  
  included do
    def paginate(scope)
      scope.page(params[:page]).per(params[:per_page] || 20)
    end
  end
end
```

#### Sortable
```ruby
module Sortable
  extend ActiveSupport::Concern
  
  included do
    def apply_sort(scope)
      return scope unless params[:sort].present?
      
      field, direction = params[:sort].split(',')
      scope.order(field => direction || 'asc')
    end
  end
end
```

### フィルタとコールバック

#### 認証フィルタ
- `authenticate_admin_user!`: 管理画面アクセス必須
- `check_api_token`: API認証（オプション）

#### キャッシュ制御
- `expires_in`: APIレスポンスキャッシュ
- `fresh_when`: 条件付きGET対応

#### セキュリティヘッダー
- CSP（Content Security Policy）
- X-Frame-Options
- X-Content-Type-Options

## パラメータ処理

### Strong Parameters例

#### 記事パラメータ
```ruby
def article_params
  params.require(:article).permit(
    :title, :slug, :content, :excerpt,
    :status, :published_at,
    :meta_description, :meta_keywords,
    :og_title, :og_description, :og_image,
    :work_type, :github_url, :demo_url, :tech_stack,
    :thumbnail_image,
    category_ids: [], tag_ids: []
  )
end
```

#### セクションコンテンツパラメータ
```ruby
def section_content_params
  # SectionContentParamsServiceに委譲
  @section_content_params ||= SectionContentParamsService.new(
    params, 
    @section
  ).process
end
```

## エラーハンドリング

### 共通エラー処理
```ruby
# 404 Not Found
def not_found
  respond_to do |format|
    format.html { render file: 'public/404.html', status: :not_found }
    format.json { render_error('Record not found', :not_found) }
  end
end

# 422 Unprocessable Entity
def unprocessable_entity(exception)
  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path, alert: exception.message) }
    format.json { render_error(exception.message, :unprocessable_entity) }
  end
end
```

### バリデーションエラー
```ruby
if @article.save
  redirect_to admin_articles_path, notice: '記事を作成しました'
else
  flash.now[:alert] = @article.errors.full_messages.join('、')
  render :new, status: :unprocessable_entity
end
```