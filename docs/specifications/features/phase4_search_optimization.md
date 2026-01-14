# ブログ検索・最適化機能 仕様書

## 📅 作成日・更新日
- **作成日**: 2024-12-26
- **最終更新**: 2025-12-27
- **ステータス**: 🟡 実装中（Phase4.3）
- **実装方針**: 段階的アプローチ（Phase 4.3: 基本検索、Phase 5: UI強化）
- **UX改善**: 検索フィルターとナビゲーションの分離（2025-12-27追加）

---

## 🎯 概要

### 目的
ブログ記事の検索機能を実装し、ユーザーが目的の記事を素早く見つけられるようにする。
また、基本的なキャッシュ戦略を導入してパフォーマンスを最適化する。

### UX上の重要な考慮事項（2025-12-27追加）

**問題**: サイドバーのカテゴリナビゲーションと検索フィルターの混同

ユーザーは以下のように認識する：
- **サイドバーのカテゴリ** = ページ遷移のナビゲーション（検索とは独立）
- **検索ボックス** = 検索フィルター

しかし、実装が両方を連動させると：
- キーワード「集合写真」+ サイドバーで「雑記」カテゴリをクリック
- → AND条件で0件 → 「記事が見つかりませんでした」
- → ユーザー混乱：「なぜ雑記カテゴリに記事がないの？」

**解決策**: 検索フィルターを検索エリアに統合し、サイドバーは純粋なナビゲーションとして機能させる

### ユーザーストーリー
- 読者として、キーワードで記事を検索したい、なぜなら興味のある記事を素早く見つけたいから
- 読者として、カテゴリやタグで記事を絞り込みたい、なぜなら特定のトピックの記事をまとめて読みたいから
- 読者として、検索結果が素早く表示されてほしい、なぜなら待ち時間なく快適に閲覧したいから
- **読者として、検索とナビゲーションを混同したくない、なぜなら直感的に操作したいから**（2025-12-27追加）

---

## ✅ 要件

### 機能要件
- [ ] **基本検索機能**
  - キーワード検索（記事タイトル・本文・抜粋）
  - 検索結果一覧表示
  - 検索キーワードのハイライト表示
  - 検索結果のページネーション
  
- [ ] **フィルタリング機能**
  - カテゴリによる絞り込み
  - タグによる絞り込み
  - 公開ステータスによる絞り込み（管理画面のみ）
  - 複数条件の組み合わせ
  
- [ ] **検索UI**
  - ブログ一覧ページに検索バー配置
  - フィルタUIの実装（ドロップダウン/チェックボックス）
  - 検索中のローディング表示
  - 検索結果件数の表示

- [ ] **パフォーマンス最適化**
  - 検索結果のキャッシュ（頻繁に検索されるクエリ）
  - カテゴリ/タグ一覧のキャッシュ
  - N+1クエリの解消
  - データベースインデックスの最適化

### 非機能要件
- **パフォーマンス**: 検索レスポンスタイム < 500ms
- **スケーラビリティ**: 1000記事以上でも快適に動作
- **ユーザビリティ**: 直感的な検索UI、モバイル対応
- **SEO**: 検索結果ページのSEO対応（メタタグ、URL構造）

---

## 🖼️ 画面仕様

### UI/UX詳細

#### ブログ一覧ページ（検索UI統合版）- Phase 4.3実装

```
┌─────────────────────────────────────────────────────────────┐
│ Blog                                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌─────────────────────────────────────────────────────┐   │
│ │ 🔍 記事を検索                                       │   │
│ │                                                     │   │
│ │ [キーワードを入力...              ] [検索]         │   │
│ │                                                     │   │
│ │ 絞り込み: カテゴリ [すべて ▼]  タグ [すべて ▼]    │   │
│ │                                                     │   │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │   │
│ │ 「集合写真」の検索結果: 1件                         │   │
│ │ [カテゴリ: 技術 ✕] [✕ すべてクリア]               │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ ┌─────────────────────────────────────────────────────┐   │
│ │ 記事タイトル（集合写真がハイライト）                │   │
│ │ 2024-12-26 | 技術                                  │   │
│ │ 記事の抜粋...集合写真...                            │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ [1] 2 3 ... 次へ >                                         │
└─────────────────────────────────────────────────────────────┘

サイドバー（検索とは独立したナビゲーション）:
┌─────────────────┐
│ カテゴリ        │
│ ・技術 (10)     │  ← クリックすると検索条件をクリアして
│ ・雑記 (5)      │     そのカテゴリの記事一覧を表示
│ ・日記 (3)      │
│                 │
│ [✕ クリア]      │  ← カテゴリ選択中のみ表示
└─────────────────┘
```

**重要な変更点**:

1. **検索フィルターの統合**
   - カテゴリ・タグのドロップダウンを検索エリア内に配置
   - 検索とフィルターが連動していることを視覚的に明示

2. **適用中のフィルター表示**
   - 選択中のカテゴリ・タグをバッジで表示
   - 各バッジに✕ボタンで個別削除可能
   - 「すべてクリア」ボタンで一括リセット

3. **サイドバーの役割明確化**
   - サイドバーのカテゴリは検索とは独立
   - クリックすると検索条件をクリアしてカテゴリページへ遷移
   - カテゴリ選択中は「✕ クリア」ボタンを表示

4. **検索結果が0件の場合**
   - 分かりやすいメッセージ
   - 「すべての記事を見る」リンクを表示

#### 検索結果ページ（/blog/search）

```
┌─────────────────────────────────────────────────┐
│ 検索結果: "Rails" - 15件                        │
├─────────────────────────────────────────────────┤
│                                                 │
│ 🔍 [Rails              ] [検索]                │
│                                                 │
│ フィルタ:                                       │
│ ☑ カテゴリ: プログラミング (10)                │
│ ☐ カテゴリ: インフラ (5)                       │
│                                                 │
│ ☑ タグ: Ruby (8)                               │
│ ☑ タグ: Rails (15)                             │
│                                                 │
│ ┌─────────────────────────────────────────┐   │
│ │ Railsで始めるWeb開発                     │   │
│ │ 2024-12-20 | プログラミング               │   │
│ │ Railsは強力なWebフレームワーク...        │   │
│ │ #Ruby #Rails #Web開発                    │   │
│ └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### レスポンシブ対応

**モバイル表示**:
- 検索バーを全幅表示
- フィルタをアコーディオン形式で折りたたみ
- 検索結果をカード形式で縦並び

---

## 🗄️ データ仕様

### 使用するモデル
- **Article**: 既存モデル（検索対象）
- **Category**: カテゴリフィルタ
- **Tag**: タグフィルタ

### 検索対象フィールド
```ruby
# Articleモデルの検索対象
- title (タイトル) - 重み: 高
- excerpt (抜粋) - 重み: 中
- content (本文) - 重み: 低
- meta_description (メタ説明) - 重み: 中
```

### データベースインデックス追加

```ruby
# 検索パフォーマンス向上のためのインデックス
add_index :articles, :title
add_index :articles, :status
add_index :articles, :published_at
add_index :articles, [:status, :published_at]

# 全文検索用（PostgreSQL）
execute <<-SQL
  CREATE INDEX articles_search_idx ON articles 
  USING gin(to_tsvector('japanese', 
    coalesce(title, '') || ' ' || 
    coalesce(excerpt, '') || ' ' || 
    coalesce(content, '')
  ));
SQL
```

### データフロー

```
1. ユーザーが検索キーワード入力
2. フロントエンドがGETリクエスト送信
   GET /blog/search?q=keyword&category=1&tags[]=2
3. コントローラーがパラメータ解析
4. キャッシュ確認（ヒットすれば返却）
5. データベース検索実行
   - LIKE検索 or PostgreSQL全文検索
   - カテゴリ/タグでフィルタ
   - ページネーション適用
6. 検索結果をキャッシュに保存
7. ビューに検索結果を渡す
8. 検索キーワードをハイライト表示
```

---

## 🔌 API仕様

### エンドポイント

#### 検索API（公開）
```
GET /blog/search
GET /api/v1/articles/search
```

### リクエストパラメータ

```ruby
{
  q: String,              # 検索キーワード（任意）
  category_id: Integer,   # カテゴリID（任意）
  tag_ids: Array,         # タグID配列（任意）
  page: Integer,          # ページ番号（デフォルト: 1）
  per_page: Integer       # 1ページあたりの件数（デフォルト: 10）
}
```

### レスポンス例

```json
{
  "success": true,
  "data": {
    "articles": [
      {
        "id": 1,
        "title": "Railsで始めるWeb開発",
        "slug": "rails-web-development",
        "excerpt": "Railsは強力なWebフレームワーク...",
        "published_at": "2024-12-20T10:00:00Z",
        "thumbnail_url": "https://example.com/image.jpg",
        "categories": [
          {
            "id": 1,
            "name": "プログラミング",
            "slug": "programming"
          }
        ],
        "tags": [
          {
            "id": 1,
            "name": "Ruby"
          },
          {
            "id": 2,
            "name": "Rails"
          }
        ],
        "highlight": {
          "title": "<mark>Rails</mark>で始めるWeb開発",
          "excerpt": "<mark>Rails</mark>は強力なWebフレームワーク..."
        }
      }
    ],
    "meta": {
      "total_count": 15,
      "current_page": 1,
      "total_pages": 2,
      "per_page": 10,
      "query": "Rails",
      "filters": {
        "category_id": 1,
        "tag_ids": [1, 2]
      }
    }
  }
}
```

---

## 🧪 受け入れ基準

実装完了の判断基準：

### 検索機能
- [ ] キーワード検索が正常に動作する（タイトル・本文・抜粋から検索）
- [ ] 検索結果にキーワードがハイライト表示される
- [ ] 検索結果が正しくページネーションされる
- [ ] 検索結果件数が正しく表示される
- [ ] 検索キーワードが空の場合、全記事が表示される

### フィルタリング機能
- [ ] カテゴリで絞り込みができる
- [ ] タグで絞り込みができる
- [ ] カテゴリとタグの複数条件で絞り込みができる
- [ ] フィルタ適用後も検索キーワードが保持される

### UI/UX
- [ ] 検索バーが直感的に使える
- [ ] フィルタUIが使いやすい
- [ ] 検索中のローディング表示が適切
- [ ] モバイル表示が適切に動作する
- [ ] 検索結果ページのSEO対応（title、meta description）

### パフォーマンス
- [ ] 検索レスポンスタイムが500ms以内
- [ ] N+1クエリが発生していない
- [ ] 頻繁な検索クエリがキャッシュされている
- [ ] 1000記事以上でも快適に動作する

---

## 🧪 テスト仕様

### TDD適用判断

- [x] TDD適用: はい
- **理由**: 検索機能は境界値・エッジケースが多く、SQLインジェクション対策も重要なため

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Model | `app/models/article.rb` | `spec/models/article_spec.rb` |
| Controller | `app/controllers/blog_controller.rb` | `spec/controllers/blog_controller_spec.rb` |
| Helper | `app/helpers/search_helper.rb` | `spec/helpers/search_helper_spec.rb` |

### Model: Article

#### describe '.search'

**正常系**:
- [ ] キーワードがタイトルに含まれる記事を返す
- [ ] キーワードが本文に含まれる記事を返す
- [ ] キーワードが抜粋に含まれる記事を返す
- [ ] 複数の記事がマッチする場合、すべて返す
- [ ] 大文字小文字を区別せずに検索できる

**異常系**:
- [ ] キーワードが空文字の場合、全件を返す
- [ ] キーワードがnilの場合、全件を返す
- [ ] マッチする記事がない場合、空のリレーションを返す

**エッジケース**:
- [ ] SQLワイルドカード（%）を含むキーワードで検索できる
- [ ] SQLワイルドカード（_）を含むキーワードで検索できる
- [ ] バックスラッシュ（\）を含むキーワードで検索できる
- [ ] 前後の空白を無視して検索できる
- [ ] 複数の空白を含むキーワードで検索できる

#### describe '.by_category'

**正常系**:
- [ ] 指定したカテゴリの記事を返す
- [ ] カテゴリに属する記事が複数ある場合、すべて返す

**異常系**:
- [ ] カテゴリIDがnilの場合、全件を返す
- [ ] カテゴリIDが空文字の場合、全件を返す
- [ ] 存在しないカテゴリIDの場合、空のリレーションを返す

#### describe '.by_tags'

**正常系**:
- [ ] 指定したタグの記事を返す
- [ ] 複数のタグIDを指定した場合、いずれかのタグを持つ記事を返す
- [ ] タグに属する記事が複数ある場合、すべて返す

**異常系**:
- [ ] タグIDsがnilの場合、全件を返す
- [ ] タグIDsが空配列の場合、全件を返す
- [ ] 存在しないタグIDの場合、空のリレーションを返す

### テストコード例

```ruby
# spec/models/article_spec.rb
require 'rails_helper'

RSpec.describe Article, type: :model do
  describe '.search' do
    context '正常系' do
      it 'キーワードがタイトルに含まれる記事を返す' do
        article = create(:article, title: 'Ruby on Rails入門')
        other = create(:article, title: 'Python入門')
        
        result = Article.search('Rails')
        
        expect(result).to include(article)
        expect(result).not_to include(other)
      end
      
      it 'キーワードが本文に含まれる記事を返す' do
        article = create(:article, title: 'Web開発', content: 'Railsは強力なフレームワークです')
        other = create(:article, title: 'Web開発', content: 'Djangoは強力なフレームワークです')
        
        result = Article.search('Rails')
        
        expect(result).to include(article)
        expect(result).not_to include(other)
      end
      
      it 'キーワードが抜粋に含まれる記事を返す' do
        article = create(:article, excerpt: 'Railsの基礎を学ぶ')
        other = create(:article, excerpt: 'Pythonの基礎を学ぶ')
        
        result = Article.search('Rails')
        
        expect(result).to include(article)
        expect(result).not_to include(other)
      end
      
      it '大文字小文字を区別せずに検索できる' do
        article = create(:article, title: 'Ruby on Rails入門')
        
        result1 = Article.search('rails')
        result2 = Article.search('RAILS')
        result3 = Article.search('Rails')
        
        expect(result1).to include(article)
        expect(result2).to include(article)
        expect(result3).to include(article)
      end
    end
    
    context '異常系' do
      it 'キーワードが空文字の場合、全件を返す' do
        create_list(:article, 3)
        
        result = Article.search('')
        
        expect(result.count).to eq(3)
      end
      
      it 'キーワードがnilの場合、全件を返す' do
        create_list(:article, 3)
        
        result = Article.search(nil)
        
        expect(result.count).to eq(3)
      end
      
      it 'マッチする記事がない場合、空のリレーションを返す' do
        create(:article, title: 'Ruby入門')
        
        result = Article.search('存在しないキーワード')
        
        expect(result).to be_empty
      end
    end
    
    context 'エッジケース' do
      it 'SQLワイルドカード（%）を含むキーワードで検索できる' do
        article = create(:article, title: '100%達成')
        
        result = Article.search('100%')
        
        expect(result).to include(article)
      end
      
      it 'SQLワイルドカード（_）を含むキーワードで検索できる' do
        article = create(:article, title: 'test_data')
        
        result = Article.search('test_')
        
        expect(result).to include(article)
      end
      
      it 'バックスラッシュ（\）を含むキーワードで検索できる' do
        article = create(:article, title: 'C:\\Program Files')
        
        result = Article.search('C:\\')
        
        expect(result).to include(article)
      end
      
      it '前後の空白を無視して検索できる' do
        article = create(:article, title: 'Ruby on Rails')
        
        result = Article.search('  Rails  ')
        
        expect(result).to include(article)
      end
    end
  end
  
  describe '.by_category' do
    let(:category1) { create(:category, name: 'プログラミング') }
    let(:category2) { create(:category, name: 'インフラ') }
    
    context '正常系' do
      it '指定したカテゴリの記事を返す' do
        article1 = create(:article, categories: [category1])
        article2 = create(:article, categories: [category2])
        
        result = Article.by_category(category1.id)
        
        expect(result).to include(article1)
        expect(result).not_to include(article2)
      end
    end
    
    context '異常系' do
      it 'カテゴリIDがnilの場合、全件を返す' do
        create_list(:article, 3)
        
        result = Article.by_category(nil)
        
        expect(result.count).to eq(3)
      end
      
      it '存在しないカテゴリIDの場合、空のリレーションを返す' do
        create(:article, categories: [category1])
        
        result = Article.by_category(99999)
        
        expect(result).to be_empty
      end
    end
  end
  
  describe '.by_tags' do
    let(:tag1) { create(:tag, name: 'Ruby') }
    let(:tag2) { create(:tag, name: 'Rails') }
    let(:tag3) { create(:tag, name: 'Python') }
    
    context '正常系' do
      it '指定したタグの記事を返す' do
        article1 = create(:article, tags: [tag1])
        article2 = create(:article, tags: [tag3])
        
        result = Article.by_tags([tag1.id])
        
        expect(result).to include(article1)
        expect(result).not_to include(article2)
      end
      
      it '複数のタグIDを指定した場合、いずれかのタグを持つ記事を返す' do
        article1 = create(:article, tags: [tag1])
        article2 = create(:article, tags: [tag2])
        article3 = create(:article, tags: [tag3])
        
        result = Article.by_tags([tag1.id, tag2.id])
        
        expect(result).to include(article1, article2)
        expect(result).not_to include(article3)
      end
    end
    
    context '異常系' do
      it 'タグIDsがnilの場合、全件を返す' do
        create_list(:article, 3)
        
        result = Article.by_tags(nil)
        
        expect(result.count).to eq(3)
      end
      
      it 'タグIDsが空配列の場合、全件を返す' do
        create_list(:article, 3)
        
        result = Article.by_tags([])
        
        expect(result.count).to eq(3)
      end
    end
  end
end
```

### Controller: BlogController

```ruby
# spec/controllers/blog_controller_spec.rb
require 'rails_helper'

RSpec.describe BlogController, type: :controller do
  describe 'GET #search' do
    context '正常系' do
      it '検索結果を表示する' do
        article = create(:article, title: 'Ruby on Rails', status: 'published')
        
        get :search, params: { q: 'Rails' }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:articles)).to include(article)
        expect(assigns(:query)).to eq('Rails')
      end
      
      it 'カテゴリフィルタが機能する' do
        category = create(:category, name: 'プログラミング')
        article1 = create(:article, categories: [category], status: 'published')
        article2 = create(:article, status: 'published')
        
        get :search, params: { category_id: category.id }
        
        expect(assigns(:articles)).to include(article1)
        expect(assigns(:articles)).not_to include(article2)
      end
      
      it 'タグフィルタが機能する' do
        tag = create(:tag, name: 'Ruby')
        article1 = create(:article, tags: [tag], status: 'published')
        article2 = create(:article, status: 'published')
        
        get :search, params: { tag_ids: [tag.id] }
        
        expect(assigns(:articles)).to include(article1)
        expect(assigns(:articles)).not_to include(article2)
      end
      
      it 'ページネーションが機能する' do
        create_list(:article, 15, status: 'published')
        
        get :search, params: { page: 1, per_page: 10 }
        
        expect(assigns(:articles).count).to eq(10)
      end
    end
    
    context '異常系' do
      it 'キーワードがない場合、全件を表示する' do
        create_list(:article, 3, status: 'published')
        
        get :search
        
        expect(assigns(:articles).count).to eq(3)
      end
    end
    
    context 'SEO' do
      it 'メタタグが設定される' do
        get :search, params: { q: 'Rails' }
        
        expect(assigns(:meta_tags)[:title]).to include('Rails')
        expect(assigns(:meta_tags)[:noindex]).to be true
      end
    end
  end
end
```

### Helper: SearchHelper

```ruby
# spec/helpers/search_helper_spec.rb
require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  describe '#highlight_keywords' do
    it 'キーワードをハイライトする' do
      text = 'Railsは強力なフレームワークです'
      query = 'Rails'
      
      result = helper.highlight_keywords(text, query)
      
      expect(result).to include('<mark>Rails</mark>')
    end
    
    it '大文字小文字を区別せずにハイライトする' do
      text = 'Railsは強力なフレームワークです'
      query = 'rails'
      
      result = helper.highlight_keywords(text, query)
      
      expect(result).to include('<mark>Rails</mark>')
    end
    
    it 'XSS攻撃を防ぐ' do
      text = '<script>alert("XSS")</script>'
      query = 'script'
      
      result = helper.highlight_keywords(text, query)
      
      expect(result).not_to include('<script>')
      expect(result).to include('&lt;script&gt;')
    end
    
    it 'クエリが空の場合、元のテキストを返す' do
      text = 'Railsは強力なフレームワークです'
      
      result = helper.highlight_keywords(text, '')
      
      expect(result).to eq(text)
    end
  end
end
```

### テストデータ（FactoryBot）

```ruby
# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    title { 'サンプル記事' }
    content { 'サンプル本文' }
    excerpt { 'サンプル抜粋' }
    status { 'draft' }
    association :admin_user
    
    trait :published do
      status { 'published' }
      published_at { Time.current }
    end
    
    trait :with_category do
      after(:create) do |article|
        article.categories << create(:category)
      end
    end
    
    trait :with_tags do
      after(:create) do |article|
        article.tags << create_list(:tag, 3)
      end
    end
  end
end

# spec/factories/categories.rb
FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "カテゴリ#{n}" }
    sequence(:slug) { |n| "category-#{n}" }
  end
end

# spec/factories/tags.rb
FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "タグ#{n}" }
  end
end
```

### パフォーマンステスト

```ruby
# spec/models/article_spec.rb (追加)
describe 'パフォーマンス' do
  it '1000件の記事でも500ms以内に検索できる' do
    create_list(:article, 1000, :published)
    
    start_time = Time.current
    Article.published.search('test').to_a
    end_time = Time.current
    
    expect(end_time - start_time).to be < 0.5
  end
  
  it 'N+1クエリが発生しない' do
    create_list(:article, 10, :published, :with_category, :with_tags)
    
    expect {
      Article.published
             .includes(:categories, :tags)
             .search('test')
             .each do |article|
               article.categories.map(&:name)
               article.tags.map(&:name)
             end
    }.to perform_queries(count: 3..5)  # 適切なクエリ数
  end
end
```

### カバレッジ目標

- Model: 95%以上
- Controller: 90%以上
- Helper: 95%以上

---

## 💡 実装メモ

### 実装方針: 段階的アプローチ

#### Phase 4.3（今回実装）: 基本検索機能

**目標**: 最小限の変更で検索機能を動作させる

**実装内容**:
1. Articleモデルに検索スコープ追加
2. BlogControllerのindexアクションを拡張
3. 既存のindex.html.erbに検索バーを追加
4. 検索結果のハイライト表示

**メリット**:
- 既存ビューを活用（コード重複なし）
- 最小限の変更で動作
- TDDで確実に実装
- 既存機能を壊さない

#### Phase 5（将来実装）: UI強化

**目標**: 専用検索ページと高度なフィルタUI

**実装内容**:
1. search.html.erb新規作成
2. フィルタUIの実装（サイドバー）
3. 検索候補の表示
4. インクリメンタルサーチ

---

### 実装対象ファイル（Phase 4.3）- UX改善版

1. **モデル**: `app/models/article.rb`
   - `search` スコープの追加
   - `by_category` スコープの追加
   - `by_tag` スコープの追加（単数形に変更）

2. **コントローラー**: `app/controllers/blog_controller.rb`
   - `index` アクションの拡張（検索パラメータ処理）
   - SEO対応（検索結果ページはnoindex）

3. **ビュー**: `app/views/blog/index.html.erb`
   - 検索エリアの追加（統合フィルター付き）
   - 適用中のフィルター表示
   - 検索結果件数の表示
   - 0件時の分かりやすいメッセージ

4. **ビュー**: `app/views/blog/_sidebar.html.erb`
   - カテゴリナビゲーションの独立化
   - カテゴリクリック時に検索条件をクリア
   - カテゴリ選択中の視覚的フィードバック
   - 「✕ クリア」ボタンの追加

5. **ヘルパー**: `app/helpers/search_helper.rb`
   - キーワードハイライト処理

6. **ルーティング**: `config/routes.rb`
   - 既存のblog#indexを活用（変更不要）

---

## 💡 Claude Codeへの実装指示

### 🎯 実装の最重要ポイント

**UX問題の解決が最優先です**:
- サイドバーのカテゴリは検索とは独立したナビゲーション
- 検索フィルター（カテゴリ・タグ）は検索エリア内に統合
- ユーザーが混乱しないUI設計

### 実装手順

#### Step 1: Modelの実装
  return all if query.blank?
  
  where(
    "title ILIKE :q OR excerpt ILIKE :q OR content ILIKE :q",
    q: "%#{sanitize_sql_like(query)}%"
  )
}

scope :by_category, ->(category_id) {
  return all if category_id.blank?
  joins(:categories).where(categories: { id: category_id })
}

scope :by_tags, ->(tag_ids) {
  return all if tag_ids.blank?
  joins(:tags).where(tags: { id: tag_ids })
}
```

```ruby
# app/controllers/blog_controller.rb
def index
  @articles = Article.published
                    .search(params[:q])
                    .by_category(params[:category_id])
                    .by_tags(params[:tag_ids])
                    .order(published_at: :desc)
                    .page(params[:page])
                    .per(10)
  
  @query = params[:q]
  @categories = Category.all
  @tags = Tag.all
end
```

```erb
<!-- app/views/blog/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <!-- 検索バー -->
  <div class="mb-6">
    <%= form_with url: blog_index_path, method: :get, local: true, class: "flex gap-2" do |f| %>
      <%= f.text_field :q, 
          value: params[:q], 
          placeholder: "記事を検索...", 
          class: "flex-1 px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500" %>
      <%= f.submit "検索", class: "px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700" %>
    <% end %>
  </div>
  
  <!-- 検索結果件数 -->
  <% if @query.present? %>
    <p class="mb-4 text-gray-600">
      「<%= @query %>」の検索結果: <%= @articles.total_count %>件
    </p>
  <% end %>
  
  <!-- 既存の記事一覧表示 -->
  <div class="grid gap-6">
    <%= render @articles %>
  </div>
  
  <!-- ページネーション -->
  <%= paginate @articles %>
</div>
```

#### Phase 5（高度な検索）- 将来実装予定
- PostgreSQL全文検索（pg_search gem）
- インクリメンタルサーチ（リアルタイム検索）
- 検索候補の表示
- 検索履歴機能

### キャッシュ戦略

```ruby
# app/controllers/blog_controller.rb
def search
  cache_key = "blog_search/#{params[:q]}/#{params[:category_id]}/#{params[:tag_ids]}/#{params[:page]}"
  
  @articles = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    Article.published
           .search(params[:q])
           .by_category(params[:category_id])
           .by_tags(params[:tag_ids])
           .order(published_at: :desc)
           .page(params[:page])
           .per(10)
  end
end
```

### パフォーマンス最適化

1. **Eager Loading**:
```ruby
Article.includes(:categories, :tags, thumbnail_image_attachment: :blob)
```

2. **データベースインデックス**:
```ruby
# db/migrate/XXXXXX_add_search_indexes.rb
class AddSearchIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :articles, :title
    add_index :articles, :status
    add_index :articles, [:status, :published_at]
  end
end
```

3. **カウンタキャッシュ**:
```ruby
# カテゴリ・タグの記事数をキャッシュ
add_column :categories, :articles_count, :integer, default: 0
add_column :tags, :articles_count, :integer, default: 0
```

### キーワードハイライト実装

```ruby
# app/helpers/search_helper.rb
module SearchHelper
  def highlight_keywords(text, query)
    return text if query.blank?
    
    # HTMLエスケープしてからハイライト
    escaped_text = ERB::Util.html_escape(text)
    keywords = query.split(/\s+/)
    
    keywords.each do |keyword|
      escaped_keyword = Regexp.escape(keyword)
      escaped_text = escaped_text.gsub(
        /#{escaped_keyword}/i,
        '<mark>\0</mark>'
      )
    end
    
    escaped_text.html_safe
  end
  
  def truncate_with_highlight(text, query, length: 200)
    # キーワード周辺のテキストを抽出
    if query.present? && text.include?(query)
      start_pos = [text.index(query) - 50, 0].max
      truncated = text[start_pos, length]
      "...#{highlight_keywords(truncated, query)}..."
    else
      truncate(text, length: length)
    end
  end
end
```

### SEO対応

```ruby
# app/controllers/blog_controller.rb
def search
  @query = params[:q]
  @articles = # ... 検索処理
  
  # SEOメタタグ設定
  set_meta_tags(
    title: "「#{@query}」の検索結果 - Blog",
    description: "「#{@query}」に関する記事#{@articles.total_count}件を表示しています。",
    noindex: true  # 検索結果ページはインデックスしない
  )
end
```

### ルーティング

```ruby
# config/routes.rb
# 既存のルーティングをそのまま使用
get 'blog', to: 'blog#index', as: :blog_index

# Phase 5で追加予定
# get 'blog/search', to: 'blog#search', as: :blog_search

namespace :api do
  namespace :v1 do
    resources :articles do
      collection do
        get :search
      end
    end
  end
end
```

---

## 📊 実装履歴

| 日付 | 担当 | 内容 |
|------|------|------|
| 2024-12-26 | Kiro | 初版作成（Phase4.3実装待ち） |

---

## 🔗 関連ドキュメント

- Phase計画書: `/docs/development/phase_plan_rails_8_1_1.md`
- 総合仕様書: `/docs/specifications/spec.md`
- 既存実装: `app/controllers/blog_controller.rb`
- 既存実装: `app/models/article.rb`

---

## 📝 補足

### Phase 4 vs Phase 5の検索機能比較

| 機能 | Phase 4（基本検索） | Phase 5（高度な検索） |
|------|-------------------|---------------------|
| 検索方式 | LIKE検索 | PostgreSQL全文検索 |
| 検索速度 | 中程度 | 高速 |
| 検索精度 | 部分一致 | 形態素解析・スコアリング |
| リアルタイム検索 | ❌ | ✅ |
| 検索候補 | ❌ | ✅ |
| 検索履歴 | ❌ | ✅ |
| ファセット検索 | 基本的なフィルタ | 高度なファセット |

### 実装優先度
Phase 4.3での実装を予定。Phase 4.2（画像キャプション）完了後に着手する。

### 技術的制約
- PostgreSQL 16の機能を活用
- Rails 8.0.4のキャッシュ機能を使用
- 既存のkaminari gemでページネーション
- 日本語検索に対応（ILIKE使用）

### パフォーマンス目標
- 検索レスポンスタイム: < 500ms
- 同時検索リクエスト: 100req/s
- キャッシュヒット率: > 70%
- データベースクエリ数: < 5 queries/request
