# Project（実績・ポートフォリオ作品）機能仕様書

## 1. 概要

### 1.1 目的
ポートフォリオサイトの「Works」セクションで表示する実績・プロジェクトを管理する機能を提供する。

### 1.2 対象
- **管理者**: プロジェクトの登録・編集・削除・並び替え
- **訪問者**: ポートフォリオページでのプロジェクト閲覧

## 2. データモデル仕様

### 2.1 Projectテーブル設計

```sql
CREATE TABLE projects (
    id BIGSERIAL PRIMARY KEY,
    admin_user_id BIGINT NOT NULL,
    
    -- 基本情報
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    subtitle VARCHAR(255),
    description TEXT NOT NULL,
    
    -- プロジェクト詳細
    client_name VARCHAR(255),
    project_type VARCHAR(100), -- web_app, mobile_app, system, consulting, other
    role VARCHAR(255), -- プロジェクトマネージャー, リードエンジニア, フルスタック開発者等
    team_size INTEGER,
    duration_months INTEGER,
    
    -- 期間
    started_at DATE,
    completed_at DATE,
    
    -- 技術スタック
    technologies TEXT[], -- ['Ruby on Rails', 'PostgreSQL', 'React', 'AWS']
    
    -- リンク
    project_url VARCHAR(500),
    github_url VARCHAR(500),
    demo_url VARCHAR(500),
    
    -- 画像
    thumbnail_url VARCHAR(500),
    cover_image_url VARCHAR(500),
    screenshots JSONB DEFAULT '[]', -- 複数のスクリーンショット情報
    
    -- 成果・インパクト
    achievements TEXT[], -- ['売上20%向上', 'ユーザー数3倍増加']
    testimonial TEXT, -- クライアントからの推薦文
    testimonial_author VARCHAR(255),
    testimonial_author_title VARCHAR(255),
    
    -- 表示制御
    is_featured BOOLEAN DEFAULT false, -- 注目プロジェクト
    is_published BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    
    -- カテゴリ（複数選択可能）
    categories TEXT[], -- ['web_development', 'consulting', 'ai_ml']
    
    -- SEO
    meta_description TEXT,
    meta_keywords TEXT,
    
    -- タイムスタンプ
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- 外部キー制約
    FOREIGN KEY (admin_user_id) REFERENCES admin_users(id) ON DELETE RESTRICT
);

-- インデックス
CREATE UNIQUE INDEX idx_projects_slug ON projects(slug);
CREATE INDEX idx_projects_published_order ON projects(is_published, display_order, created_at DESC);
CREATE INDEX idx_projects_featured ON projects(is_featured) WHERE is_featured = true;
CREATE INDEX idx_projects_technologies ON projects USING gin(technologies);
CREATE INDEX idx_projects_categories ON projects USING gin(categories);
```

### 2.2 projectsテーブルのマイグレーション

```ruby
class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :admin_user, null: false, foreign_key: true
      
      # 基本情報
      t.string :title, null: false
      t.string :slug, null: false
      t.string :subtitle
      t.text :description, null: false
      
      # プロジェクト詳細
      t.string :client_name
      t.string :project_type
      t.string :role
      t.integer :team_size
      t.integer :duration_months
      
      # 期間
      t.date :started_at
      t.date :completed_at
      
      # 技術スタック
      t.text :technologies, array: true, default: []
      
      # リンク
      t.string :project_url
      t.string :github_url
      t.string :demo_url
      
      # 画像
      t.string :thumbnail_url
      t.string :cover_image_url
      t.jsonb :screenshots, default: []
      
      # 成果・インパクト
      t.text :achievements, array: true, default: []
      t.text :testimonial
      t.string :testimonial_author
      t.string :testimonial_author_title
      
      # 表示制御
      t.boolean :is_featured, default: false
      t.boolean :is_published, default: true
      t.integer :display_order, default: 0
      
      # カテゴリ
      t.text :categories, array: true, default: []
      
      # SEO
      t.text :meta_description
      t.text :meta_keywords
      
      t.timestamps
    end
    
    add_index :projects, :slug, unique: true
    add_index :projects, [:is_published, :display_order, :created_at], name: 'idx_projects_published_order'
    add_index :projects, :is_featured, where: 'is_featured = true'
    add_index :projects, :technologies, using: :gin
    add_index :projects, :categories, using: :gin
  end
end
```

## 3. モデル仕様

### 3.1 Projectモデル

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :admin_user
  
  # バリデーション
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :description, presence: true
  validates :project_type, inclusion: { in: %w[web_app mobile_app system consulting other] }, allow_nil: true
  
  # スコープ
  scope :published, -> { where(is_published: true) }
  scope :featured, -> { where(is_featured: true) }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }
  scope :with_technology, ->(tech) { where('? = ANY(technologies)', tech) }
  scope :with_category, ->(cat) { where('? = ANY(categories)', cat) }
  
  # コールバック
  before_validation :generate_slug, on: :create
  after_save :update_section_cache
  
  # 定数
  PROJECT_TYPES = {
    web_app: 'Webアプリケーション',
    mobile_app: 'モバイルアプリ',
    system: 'システム開発',
    consulting: 'コンサルティング',
    other: 'その他'
  }.freeze
  
  CATEGORIES = {
    web_development: 'Web開発',
    mobile_development: 'モバイル開発',
    backend_development: 'バックエンド開発',
    frontend_development: 'フロントエンド開発',
    ai_ml: 'AI・機械学習',
    data_engineering: 'データエンジニアリング',
    consulting: 'コンサルティング',
    project_management: 'プロジェクト管理'
  }.freeze
  
  # Active Storage（将来実装）
  # has_one_attached :thumbnail
  # has_one_attached :cover_image
  # has_many_attached :screenshots
  
  # メソッド
  def to_param
    slug
  end
  
  def project_type_name
    PROJECT_TYPES[project_type.to_sym] if project_type.present?
  end
  
  def duration_text
    return nil unless started_at.present?
    
    if completed_at.present?
      "#{started_at.strftime('%Y年%m月')} - #{completed_at.strftime('%Y年%m月')}"
    else
      "#{started_at.strftime('%Y年%m月')} - 現在"
    end
  end
  
  def formatted_technologies
    technologies.join(', ')
  end
  
  def formatted_categories
    categories.map { |cat| CATEGORIES[cat.to_sym] }.compact.join(', ')
  end
  
  private
  
  def generate_slug
    self.slug = title.parameterize if slug.blank? && title.present?
  end
  
  def update_section_cache
    # Worksセクションのキャッシュをクリア
    Rails.cache.delete('portfolio_works_section')
  end
end
```

## 4. 管理画面仕様

### 4.1 一覧画面（/admin/projects）

#### 表示項目
- タイトル
- クライアント名
- プロジェクトタイプ
- 期間
- 公開状態
- 注目フラグ
- 表示順
- 操作（編集・削除・プレビュー）

#### 機能
- 並び替え（ドラッグ&ドロップ）
- 一括公開/非公開
- フィルタリング（公開状態、タイプ、カテゴリ）
- 検索（タイトル、説明文）

### 4.2 新規作成・編集画面（/admin/projects/new, /admin/projects/:id/edit）

#### 入力フォーム構成

##### 基本情報タブ
- タイトル（必須）
- サブタイトル
- スラッグ（URL用、自動生成可）
- 説明文（必須、Markdownエディタ）

##### プロジェクト詳細タブ
- クライアント名
- プロジェクトタイプ（セレクトボックス）
- 担当役割
- チーム規模
- 期間（開始日・終了日）
- プロジェクト期間（月数、自動計算）

##### 技術・カテゴリタブ
- 使用技術（タグ入力、オートコンプリート）
- カテゴリ（チェックボックス、複数選択）

##### メディアタブ
- サムネイル画像（アップロード・URL入力）
- カバー画像（アップロード・URL入力）
- スクリーンショット（複数アップロード可能）

##### 成果・推薦タブ
- 主な成果（複数入力、動的追加）
- 推薦文
- 推薦者名
- 推薦者肩書き

##### リンクタブ
- プロジェクトURL
- GitHubリポジトリURL
- デモサイトURL

##### 公開設定タブ
- 公開状態
- 注目プロジェクトフラグ
- 表示順
- メタディスクリプション
- メタキーワード

### 4.3 コントローラー実装

```ruby
# app/controllers/admin/projects_controller.rb
class Admin::ProjectsController < Admin::BaseController
  before_action :set_project, only: [:show, :edit, :update, :destroy]
  
  def index
    @projects = Project.includes(:admin_user)
                      .ordered
                      .page(params[:page])
  end
  
  def new
    @project = Project.new
  end
  
  def create
    @project = current_admin_user.projects.build(project_params)
    
    if @project.save
      redirect_to admin_projects_path, notice: 'プロジェクトを作成しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @project.update(project_params)
      redirect_to admin_projects_path, notice: 'プロジェクトを更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @project.destroy!
    redirect_to admin_projects_path, notice: 'プロジェクトを削除しました。'
  end
  
  # 並び順更新（Ajax）
  def reorder
    params[:project_ids].each_with_index do |id, index|
      Project.find(id).update(display_order: index)
    end
    
    head :ok
  end
  
  private
  
  def set_project
    @project = Project.find(params[:id])
  end
  
  def project_params
    params.require(:project).permit(
      :title, :subtitle, :slug, :description,
      :client_name, :project_type, :role, :team_size, :duration_months,
      :started_at, :completed_at,
      :project_url, :github_url, :demo_url,
      :thumbnail_url, :cover_image_url,
      :testimonial, :testimonial_author, :testimonial_author_title,
      :is_featured, :is_published, :display_order,
      :meta_description, :meta_keywords,
      technologies: [], categories: [], achievements: []
    )
  end
end
```

## 5. 公開画面仕様

### 5.1 ポートフォリオページでの表示

#### Worksセクション表示
```erb
<!-- app/views/portfolio/_works_section.html.erb -->
<section id="works" class="py-20">
  <div class="container mx-auto px-4">
    <h2 class="text-4xl font-bold text-center mb-12">Works</h2>
    
    <!-- 注目プロジェクト -->
    <% if @featured_projects.any? %>
      <div class="mb-12">
        <h3 class="text-2xl font-semibold mb-6">注目プロジェクト</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <% @featured_projects.each do |project| %>
            <%= render 'portfolio/project_card_large', project: project %>
          <% end %>
        </div>
      </div>
    <% end %>
    
    <!-- その他のプロジェクト -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <% @projects.each do |project| %>
        <%= render 'portfolio/project_card', project: project %>
      <% end %>
    </div>
  </div>
</section>
```

### 5.2 プロジェクト詳細ページ（/projects/:slug）

```erb
<!-- app/views/projects/show.html.erb -->
<article class="max-w-6xl mx-auto px-4 py-12">
  <!-- ヘッダー -->
  <header class="mb-8">
    <h1 class="text-4xl font-bold mb-2"><%= @project.title %></h1>
    <% if @project.subtitle.present? %>
      <p class="text-xl text-gray-600"><%= @project.subtitle %></p>
    <% end %>
    
    <!-- メタ情報 -->
    <div class="flex flex-wrap gap-4 mt-4 text-sm text-gray-500">
      <% if @project.client_name.present? %>
        <span>クライアント: <%= @project.client_name %></span>
      <% end %>
      <% if @project.duration_text.present? %>
        <span>期間: <%= @project.duration_text %></span>
      <% end %>
      <% if @project.team_size.present? %>
        <span>チーム規模: <%= @project.team_size %>名</span>
      <% end %>
    </div>
  </header>
  
  <!-- カバー画像 -->
  <% if @project.cover_image_url.present? %>
    <div class="mb-8">
      <%= image_tag @project.cover_image_url, 
          alt: @project.title, 
          class: "w-full rounded-lg shadow-lg" %>
    </div>
  <% end %>
  
  <!-- プロジェクト詳細 -->
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
    <!-- メインコンテンツ -->
    <div class="lg:col-span-2 space-y-8">
      <!-- 説明 -->
      <section>
        <h2 class="text-2xl font-semibold mb-4">プロジェクト概要</h2>
        <div class="prose max-w-none">
          <%= sanitize(markdown_to_html(@project.description)) %>
        </div>
      </section>
      
      <!-- 成果 -->
      <% if @project.achievements.any? %>
        <section>
          <h2 class="text-2xl font-semibold mb-4">主な成果</h2>
          <ul class="list-disc list-inside space-y-2">
            <% @project.achievements.each do |achievement| %>
              <li><%= achievement %></li>
            <% end %>
          </ul>
        </section>
      <% end %>
      
      <!-- スクリーンショット -->
      <% if @project.screenshots.any? %>
        <section>
          <h2 class="text-2xl font-semibold mb-4">スクリーンショット</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <% @project.screenshots.each do |screenshot| %>
              <img src="<%= screenshot['url'] %>" 
                   alt="<%= screenshot['caption'] || 'スクリーンショット' %>"
                   class="rounded-lg shadow-md">
            <% end %>
          </div>
        </section>
      <% end %>
      
      <!-- 推薦文 -->
      <% if @project.testimonial.present? %>
        <section class="bg-gray-50 p-6 rounded-lg">
          <h2 class="text-2xl font-semibold mb-4">クライアントの声</h2>
          <blockquote class="italic">
            "<%= @project.testimonial %>"
          </blockquote>
          <% if @project.testimonial_author.present? %>
            <p class="mt-4 text-right">
              — <%= @project.testimonial_author %>
              <% if @project.testimonial_author_title.present? %>
                <span class="text-gray-600">(<%= @project.testimonial_author_title %>)</span>
              <% end %>
            </p>
          <% end %>
        </section>
      <% end %>
    </div>
    
    <!-- サイドバー -->
    <aside class="space-y-6">
      <!-- 技術スタック -->
      <div class="bg-white p-6 rounded-lg shadow">
        <h3 class="text-lg font-semibold mb-3">使用技術</h3>
        <div class="flex flex-wrap gap-2">
          <% @project.technologies.each do |tech| %>
            <span class="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm">
              <%= tech %>
            </span>
          <% end %>
        </div>
      </div>
      
      <!-- プロジェクト情報 -->
      <div class="bg-white p-6 rounded-lg shadow">
        <h3 class="text-lg font-semibold mb-3">プロジェクト情報</h3>
        <dl class="space-y-2">
          <% if @project.project_type_name.present? %>
            <dt class="font-medium">タイプ</dt>
            <dd class="text-gray-600"><%= @project.project_type_name %></dd>
          <% end %>
          
          <% if @project.role.present? %>
            <dt class="font-medium">担当役割</dt>
            <dd class="text-gray-600"><%= @project.role %></dd>
          <% end %>
          
          <% if @project.duration_months.present? %>
            <dt class="font-medium">期間</dt>
            <dd class="text-gray-600"><%= @project.duration_months %>ヶ月</dd>
          <% end %>
        </dl>
      </div>
      
      <!-- リンク -->
      <div class="bg-white p-6 rounded-lg shadow">
        <h3 class="text-lg font-semibold mb-3">リンク</h3>
        <div class="space-y-2">
          <% if @project.project_url.present? %>
            <%= link_to @project.project_url, target: "_blank", rel: "noopener", 
                class: "flex items-center text-blue-600 hover:text-blue-800" do %>
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                      d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              プロジェクトサイト
            <% end %>
          <% end %>
          
          <% if @project.github_url.present? %>
            <%= link_to @project.github_url, target: "_blank", rel: "noopener", 
                class: "flex items-center text-blue-600 hover:text-blue-800" do %>
              <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
              </svg>
              GitHub
            <% end %>
          <% end %>
          
          <% if @project.demo_url.present? %>
            <%= link_to @project.demo_url, target: "_blank", rel: "noopener", 
                class: "flex items-center text-blue-600 hover:text-blue-800" do %>
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                      d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                      d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              デモを見る
            <% end %>
          <% end %>
        </div>
      </div>
    </aside>
  </div>
</article>
```

## 6. API仕様

### 6.1 公開API（/api/v1/projects）

#### プロジェクト一覧取得
```
GET /api/v1/projects
```

**パラメータ**
- `featured` (boolean): 注目プロジェクトのみ
- `category` (string): カテゴリでフィルタ
- `technology` (string): 技術でフィルタ
- `page` (integer): ページ番号
- `per_page` (integer): 1ページあたりの件数（最大50）

**レスポンス例**
```json
{
  "projects": [
    {
      "id": 1,
      "title": "ECサイトリニューアルプロジェクト",
      "slug": "ec-site-renewal",
      "subtitle": "大手アパレルブランドのECサイト全面リニューアル",
      "description": "レガシーシステムから最新のRails環境への移行...",
      "client_name": "株式会社〇〇アパレル",
      "project_type": "web_app",
      "role": "テクニカルリード",
      "team_size": 8,
      "duration_months": 12,
      "started_at": "2023-01-01",
      "completed_at": "2023-12-31",
      "technologies": ["Ruby on Rails", "PostgreSQL", "React", "AWS"],
      "categories": ["web_development", "backend_development"],
      "thumbnail_url": "https://example.com/thumb.jpg",
      "project_url": "https://example-shop.com",
      "achievements": [
        "ページ読み込み速度を70%改善",
        "売上前年比120%達成に貢献"
      ],
      "is_featured": true
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 15,
    "per_page": 5
  }
}
```

#### プロジェクト詳細取得
```
GET /api/v1/projects/:slug
```

**レスポンス例**
```json
{
  "project": {
    "id": 1,
    "title": "ECサイトリニューアルプロジェクト",
    "slug": "ec-site-renewal",
    "subtitle": "大手アパレルブランドのECサイト全面リニューアル",
    "description": "レガシーシステムから最新のRails環境への移行...",
    "client_name": "株式会社〇〇アパレル",
    "project_type": "web_app",
    "role": "テクニカルリード",
    "team_size": 8,
    "duration_months": 12,
    "started_at": "2023-01-01",
    "completed_at": "2023-12-31",
    "technologies": ["Ruby on Rails", "PostgreSQL", "React", "AWS"],
    "categories": ["web_development", "backend_development"],
    "thumbnail_url": "https://example.com/thumb.jpg",
    "cover_image_url": "https://example.com/cover.jpg",
    "screenshots": [
      {
        "url": "https://example.com/screen1.jpg",
        "caption": "トップページ"
      },
      {
        "url": "https://example.com/screen2.jpg",
        "caption": "商品詳細ページ"
      }
    ],
    "project_url": "https://example-shop.com",
    "github_url": null,
    "demo_url": null,
    "achievements": [
      "ページ読み込み速度を70%改善",
      "売上前年比120%達成に貢献",
      "月間100万PVを安定処理"
    ],
    "testimonial": "技術力と提案力の高さに驚きました。プロジェクトを通じて...",
    "testimonial_author": "山田太郎",
    "testimonial_author_title": "株式会社〇〇アパレル CTO",
    "is_featured": true,
    "meta_description": "大手アパレルECサイトのフルリニューアル事例。Rails移行で売上120%達成。",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-20T15:30:00Z"
  }
}
```

### 6.2 内部管理API（/api/internal/projects）

認証必須のCRUD APIを提供（管理画面のAjax操作用）

## 7. ルーティング設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # 管理画面
  namespace :admin do
    resources :projects do
      collection do
        post :reorder
      end
    end
  end
  
  # 公開ページ
  resources :projects, only: [:show], param: :slug
  
  # API
  namespace :api do
    namespace :v1 do
      resources :projects, only: [:index, :show], param: :slug
    end
    
    namespace :internal do
      resources :projects
    end
  end
end
```

## 8. 実装優先順位

1. **Phase 1**: データベース構築
   - マイグレーション実行
   - モデル作成
   - バリデーション実装

2. **Phase 2**: 管理画面実装
   - CRUD機能
   - 並び替え機能
   - 画像アップロード（URL入力のみ）

3. **Phase 3**: 公開画面実装
   - Worksセクション表示
   - プロジェクト詳細ページ

4. **Phase 4**: API実装
   - 公開API
   - キャッシング

5. **Phase 5**: 高度な機能
   - Active Storage統合
   - 画像最適化
   - SEO強化

## 9. セキュリティ考慮事項

- 管理画面でのみ編集可能
- スラッグの一意性保証
- XSS対策（Markdown→HTMLのサニタイズ）
- 画像URLのバリデーション
- API レート制限

## 10. パフォーマンス最適化

- プロジェクト一覧のキャッシング
- 画像の遅延読み込み
- N+1クエリの回避
- インデックスの適切な設定
- CDN利用（画像配信）