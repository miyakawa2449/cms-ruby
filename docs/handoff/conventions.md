# コーディング規約・開発規約

## 📋 概要

このドキュメントは、**Kiro** と **Claude Code** が共通で使用するコーディング規約・開発規約を定義します。

---

## 🎨 Rubyコーディングスタイル

### 基本方針
- **RuboCop Rails Omakase** に準拠
- 既存コードのスタイルを踏襲

### インデント
- **2スペース**（タブ禁止）

### 命名規則
```ruby
# クラス名: PascalCase
class ArticlePublishingService
end

# メソッド名: snake_case
def publish_article
end

# 定数: SCREAMING_SNAKE_CASE
MAX_UPLOAD_SIZE = 10.megabytes

# 変数: snake_case
article_count = 10
```

### メソッド定義
```ruby
# 短いメソッド（1行）
def full_name = "#{first_name} #{last_name}"

# 長いメソッド
def complex_method
  # 処理
end

# 引数が多い場合は改行
def method_with_many_args(
  arg1:,
  arg2:,
  arg3:
)
  # 処理
end
```

### 文字列
```ruby
# ダブルクォート推奨（補間がある場合）
message = "Hello, #{name}!"

# シングルクォート（補間がない場合）
status = 'published'
```

---

## 🚂 Railsベストプラクティス

### Model
```ruby
class Article < ApplicationRecord
  # 1. include/extend
  include Publishable
  
  # 2. アソシエーション
  belongs_to :admin_user
  has_many :comments
  
  # 3. Active Storage
  has_one_attached :thumbnail
  
  # 4. バリデーション
  validates :title, presence: true
  
  # 5. enum
  enum :status, { draft: 'draft', published: 'published' }
  
  # 6. スコープ
  scope :published, -> { where(status: 'published') }
  
  # 7. コールバック
  before_save :generate_slug
  
  # 8. インスタンスメソッド
  def published?
    status == 'published'
  end
  
  # 9. クラスメソッド
  def self.recent
    order(created_at: :desc)
  end
  
  private
  
  # 10. privateメソッド
  def generate_slug
    # 処理
  end
end
```

### Controller
```ruby
class Admin::ArticlesController < Admin::BaseController
  # 1. before_action
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  
  # 2. アクション（RESTful順）
  def index
    @articles = Article.all
  end
  
  def show
  end
  
  def new
    @article = Article.new
  end
  
  def create
    @article = Article.new(article_params)
    
    if @article.save
      redirect_to admin_article_path(@article), notice: '作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @article.update(article_params)
      redirect_to admin_article_path(@article), notice: '更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @article.destroy
    redirect_to admin_articles_path, notice: '削除しました'
  end
  
  private
  
  # 3. privateメソッド
  def set_article
    @article = Article.find(params[:id])
  end
  
  def article_params
    params.require(:article).permit(:title, :content)
  end
end
```

### Service Object
```ruby
# app/services/article_publishing_service.rb
class ArticlePublishingService
  def initialize(article)
    @article = article
  end
  
  def publish
    return error_result('既に公開済みです') if @article.published?
    
    @article.update(status: 'published', published_at: Time.current)
    
    success_result('記事を公開しました')
  rescue => e
    Rails.logger.error "Publishing error: #{e.message}"
    error_result("エラーが発生しました: #{e.message}")
  end
  
  private
  
  def success_result(message)
    { success: true, message: message }
  end
  
  def error_result(message)
    { success: false, message: message }
  end
end
```

---

## 🎨 フロントエンド

### Tailwind CSS
```erb
<!-- ユーティリティクラスを使用 -->
<div class="bg-white shadow rounded-lg p-6">
  <h3 class="text-lg font-medium text-gray-900 mb-4">タイトル</h3>
  <p class="text-sm text-gray-600">説明文</p>
</div>

<!-- レスポンシブ対応 -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- コンテンツ -->
</div>
```

### Stimulus Controller
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. static定義
  static targets = ["input", "output"]
  static values = { url: String }
  
  // 2. connect
  connect() {
    console.log("Controller connected")
  }
  
  // 3. アクションメソッド
  async submit(event) {
    event.preventDefault()
    
    try {
      const response = await this.fetchData()
      this.handleSuccess(response)
    } catch (error) {
      this.handleError(error)
    }
  }
  
  // 4. privateメソッド
  async fetchData() {
    const response = await fetch(this.urlValue)
    return await response.json()
  }
  
  handleSuccess(data) {
    // 処理
  }
  
  handleError(error) {
    console.error(error)
  }
}
```

---

## 🗄️ データベース

### マイグレーション
```ruby
class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      # NOT NULL制約
      t.string :title, null: false
      t.text :content, null: false
      
      # 外部キー
      t.references :admin_user, null: false, foreign_key: true
      
      # デフォルト値
      t.string :status, default: 'draft'
      
      t.timestamps
    end
    
    # インデックス
    add_index :articles, :status
    add_index :articles, [:status, :published_at]
  end
end
```

### スキーマ命名規則
- **テーブル名**: 複数形・snake_case（例: `articles`, `article_categories`）
- **カラム名**: snake_case（例: `published_at`, `admin_user_id`）
- **外部キー**: `[モデル名]_id`（例: `admin_user_id`）
- **中間テーブル**: アルファベット順（例: `article_categories`）

---

## 📝 コメント

### 必要なコメント
```ruby
# 複雑なロジックの説明
# N+1問題を回避するためincludes使用
@articles = Article.includes(:categories, :tags).published

# 一時的な対応の説明
# TODO: Phase 5でリファクタリング予定
def temporary_method
  # 処理
end

# 外部APIの説明
# AWS SES経由でメール送信
def send_email
  # 処理
end
```

### 不要なコメント
```ruby
# ❌ 自明なコメント
# ユーザーを取得
user = User.find(params[:id])

# ❌ コードと重複するコメント
# タイトルが存在するかチェック
validates :title, presence: true
```

---

## 🧪 テスト

### RSpec
```ruby
# spec/models/article_spec.rb
RSpec.describe Article, type: :model do
  # 1. describe: メソッド・機能単位
  describe '#published?' do
    # 2. context: 条件分岐
    context 'when status is published' do
      # 3. it: 期待する動作
      it 'returns true' do
        article = create(:article, status: 'published')
        expect(article.published?).to be true
      end
    end
    
    context 'when status is draft' do
      it 'returns false' do
        article = create(:article, status: 'draft')
        expect(article.published?).to be false
      end
    end
  end
end
```

---

## 📦 Git

### コミットメッセージ
**Conventional Commits** に準拠

```
<type>: <subject>

<body>

<footer>
```

#### Type
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント変更
- `style`: コードスタイル変更（動作に影響なし）
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルド・設定変更

#### 例
```
feat: 本文内画像アップロード機能実装

- Articleモデルにcontent_images追加
- ArticleImagesController作成
- Stimulusコントローラー実装

Closes #123
```

### ブランチ命名
```
feature/機能名
fix/バグ名
refactor/リファクタリング内容
```

---

## 📂 ファイル命名

### Ruby
- **モデル**: 単数形・snake_case（例: `article.rb`）
- **コントローラー**: 複数形・snake_case（例: `articles_controller.rb`）
- **サービス**: 機能名・snake_case（例: `article_publishing_service.rb`）

### JavaScript
- **Stimulusコントローラー**: snake_case（例: `image_upload_controller.js`）

### View
- **パーシャル**: アンダースコア始まり（例: `_form.html.erb`）

---

## 🔒 セキュリティ

### 必須対応
1. **Strong Parameters**: 必ず使用
2. **CSRF対策**: Rails標準機能
3. **認証・認可**: Devise + Pundit
4. **SQLインジェクション対策**: ActiveRecord ORM
5. **XSS対策**: Rails標準エスケープ

### 禁止事項
- `eval`の使用
- 生SQLの直接実行（特別な理由がない限り）
- パスワード・APIキーのハードコード

## 🧭 エラーハンドリング規約（S1-7 P2-4で制定）

処理の呼び出し元によって、エラーの返し方を以下の2原則に統一する。

| 呼び出し元 | エラーの返し方 | 例 |
|---|---|---|
| **コントローラ向けのService** | 例外を投げず `{ success:, message:(, errors:) }` のハッシュを返す | `ArticlePublishingManager#publish`、`Media::ImageEditService#call` |
| **ジョブ・バッチ・CLI向けの処理** | 例外をそのままraiseする（リトライ・失敗記録は呼び出し側の責務） | `StorageBackupService#execute`、`DatabaseRestoreService#execute` |

- 既存コードの一斉変更は行わず、**触るファイルから漸進的に適用**する
- ログはエラーの発生箇所（Service内）で `Rails.logger.error` に残す

## 🏷️ サービス命名規約（S1-7 P2-5で制定）

- **名前空間 + 役割名詞**を標準とする（例: `Media::UploadService`、`Media::ImageEditService`、`Backup::RestoreService`）
- **エントリポイントは `call`** を標準とする（1メソッドのサービスの場合）
- 既存サービスの一括リネームは行わず、**新規作成・大きな変更時に適用**する

---

**作成者**: Kiro  
**作成日**: 2025-12-26  
**最終更新**: 2026-07-17（エラーハンドリング・サービス命名規約を追加）  
**バージョン**: 1.0
