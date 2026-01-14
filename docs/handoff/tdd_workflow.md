# TDD（テスト駆動開発）ワークフロー

## 📋 概要

このドキュメントは、**Kiro**（テスト仕様設計）と**Claude Code**（TDD実装）の協働によるテスト駆動開発のワークフローを定義します。

---

## 🎯 基本方針

### なぜKiroがテスト仕様を設計するのか

1. **仕様書との整合性**: Kiroは受け入れ基準を定義しているため、テストケースに直接変換できる
2. **第三者視点**: 実装者とは別の視点でテストケースを設計することで、見落としを防ぐ
3. **網羅性**: 正常系・異常系・エッジケースを体系的に設計できる

### TDD適用指針

| 対象 | TDD適用 | 理由 |
|------|---------|------|
| **検索機能** | 必須 | 境界値・エッジケースが多い |
| **AI機能** | 必須 | 外部API依存・モック必須 |
| **Service Object** | 必須 | 複雑なビジネスロジック |
| **セキュリティ関連** | 必須 | 認証・認可・入力検証 |
| **API エンドポイント** | 必須 | リクエスト/レスポンス検証 |
| **単純なCRUD** | 任意 | Rails標準機能で十分（ただし重要機能は推奨） |

---

## 🔄 TDDワークフロー

### Phase 1: テスト仕様設計（Kiro）

#### Step 1: 受け入れ基準からテストケース抽出

仕様書の受け入れ基準を、テスト可能な単位に分解します。

**仕様書の受け入れ基準例**:
```markdown
## 🧪 受け入れ基準

- [ ] ユーザーが検索ボックスにキーワードを入力すると、該当する記事一覧が表示される
- [ ] 検索結果がない場合、「該当する記事が見つかりません」と表示される
- [ ] 空文字で検索した場合、全件表示される
```

**テストケースへの変換**:
```markdown
## 🧪 テスト仕様

### Model: Article

#### describe '.search_by_keyword'

**正常系**:
- [ ] キーワードがタイトルに含まれる記事を返す
- [ ] キーワードが本文に含まれる記事を返す
- [ ] キーワードがタグに含まれる記事を返す
- [ ] 複数の記事がマッチする場合、すべて返す

**異常系**:
- [ ] キーワードが空文字の場合、全件を返す
- [ ] キーワードがnilの場合、全件を返す
- [ ] マッチする記事がない場合、空配列を返す

**エッジケース**:
- [ ] 特殊文字（%、_、\）を含むキーワードで検索できる
- [ ] 大文字小文字を区別せずに検索できる
- [ ] 前後の空白を無視して検索できる
```

#### Step 2: テスト仕様書作成

仕様書に「テスト仕様」セクションを追加します。

```markdown
## 🧪 テスト仕様

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Model | `app/models/article.rb` | `spec/models/article_spec.rb` |
| Service | `app/services/article_search_service.rb` | `spec/services/article_search_service_spec.rb` |
| Controller | `app/controllers/search_controller.rb` | `spec/controllers/search_controller_spec.rb` |

### Model: Article

#### describe '.search_by_keyword'

**正常系**:
```ruby
it 'キーワードがタイトルに含まれる記事を返す' do
  article = create(:article, title: 'Ruby on Rails入門')
  result = Article.search_by_keyword('Rails')
  expect(result).to include(article)
end
```

**異常系**:
```ruby
it 'キーワードが空文字の場合、全件を返す' do
  create_list(:article, 3)
  result = Article.search_by_keyword('')
  expect(result.count).to eq(3)
end
```

**エッジケース**:
```ruby
it '特殊文字を含むキーワードで検索できる' do
  article = create(:article, title: '100%達成')
  result = Article.search_by_keyword('100%')
  expect(result).to include(article)
end
```

### Service: ArticleSearchService

#### describe '#search'

**正常系**:
```ruby
it '検索結果を返す' do
  article = create(:article, title: 'Ruby on Rails')
  service = ArticleSearchService.new(keyword: 'Rails')
  result = service.search
  expect(result[:articles]).to include(article)
  expect(result[:count]).to eq(1)
end
```

**異常系**:
```ruby
it 'マッチする記事がない場合、空配列を返す' do
  service = ArticleSearchService.new(keyword: '存在しないキーワード')
  result = service.search
  expect(result[:articles]).to be_empty
  expect(result[:count]).to eq(0)
end
```

### Controller: SearchController

#### describe 'GET #index'

**正常系**:
```ruby
it '検索結果を表示する' do
  article = create(:article, title: 'Ruby on Rails')
  get :index, params: { q: 'Rails' }
  expect(response).to have_http_status(:success)
  expect(assigns(:articles)).to include(article)
end
```

**異常系**:
```ruby
it 'キーワードがない場合、全件を表示する' do
  create_list(:article, 3)
  get :index
  expect(response).to have_http_status(:success)
  expect(assigns(:articles).count).to eq(3)
end
```
```

#### Step 3: テストデータ設計

FactoryBotのファクトリ定義も設計します。

```markdown
### テストデータ（FactoryBot）

```ruby
# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    title { 'サンプル記事' }
    content { 'サンプル本文' }
    status { 'published' }
    published_at { Time.current }
    association :admin_user
    
    trait :draft do
      status { 'draft' }
      published_at { nil }
    end
    
    trait :with_tags do
      tags { 'Ruby,Rails,Web開発' }
    end
  end
end
```
```

#### Step 4: Claude Codeへの引き継ぎ

仕様書に「TDD実装メモ」を追加します。

```markdown
## 💡 TDD実装メモ（Claude Code向け）

### 実装順序

1. **Red**: テストを先に書く（失敗することを確認）
2. **Green**: 最小限の実装でテストを通す
3. **Refactor**: コードをリファクタリング

### 実装の流れ

#### Phase 1: Model層（最優先）
1. `spec/models/article_spec.rb` にテストを書く
2. `app/models/article.rb` に `search_by_keyword` スコープを実装
3. テストが通ることを確認

#### Phase 2: Service層
1. `spec/services/article_search_service_spec.rb` にテストを書く
2. `app/services/article_search_service.rb` を実装
3. テストが通ることを確認

#### Phase 3: Controller層
1. `spec/controllers/search_controller_spec.rb` にテストを書く
2. `app/controllers/search_controller.rb` を実装
3. テストが通ることを確認

### 注意点

- 各Phaseで必ず **Red → Green → Refactor** のサイクルを守る
- テストが失敗することを確認してから実装する
- 実装完了後、全テストを実行して既存機能に影響がないか確認
```

---

### Phase 2: TDD実装（Claude Code）

#### Step 1: テスト仕様の確認

```
Claude Code: 「テスト仕様を確認しました。
以下の順序でTDDを実施します：

【実装計画】
Phase 1: Model層
- spec/models/article_spec.rb
- app/models/article.rb

Phase 2: Service層
- spec/services/article_search_service_spec.rb
- app/services/article_search_service.rb

Phase 3: Controller層
- spec/controllers/search_controller_spec.rb
- app/controllers/search_controller.rb」
```

#### Step 2: Red - テストを先に書く

```ruby
# spec/models/article_spec.rb
RSpec.describe Article, type: :model do
  describe '.search_by_keyword' do
    context '正常系' do
      it 'キーワードがタイトルに含まれる記事を返す' do
        article = create(:article, title: 'Ruby on Rails入門')
        result = Article.search_by_keyword('Rails')
        expect(result).to include(article)
      end
    end
  end
end
```

**テスト実行（失敗することを確認）**:
```bash
$ bundle exec rspec spec/models/article_spec.rb
F

Failures:
  1) Article.search_by_keyword 正常系 キーワードがタイトルに含まれる記事を返す
     Failure/Error: result = Article.search_by_keyword('Rails')
     NoMethodError:
       undefined method `search_by_keyword' for Article:Class
```

#### Step 3: Green - 最小限の実装

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  scope :search_by_keyword, ->(keyword) {
    return all if keyword.blank?
    
    where('title ILIKE ?', "%#{keyword}%")
  }
end
```

**テスト実行（成功することを確認）**:
```bash
$ bundle exec rspec spec/models/article_spec.rb
.

Finished in 0.5 seconds
1 example, 0 failures
```

#### Step 4: Refactor - リファクタリング

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  scope :search_by_keyword, ->(keyword) {
    return all if keyword.blank?
    
    # タイトル、本文、タグから検索
    where(
      'title ILIKE :keyword OR content ILIKE :keyword OR tags ILIKE :keyword',
      keyword: "%#{sanitize_sql_like(keyword)}%"
    )
  }
end
```

**全テスト実行（既存機能に影響がないか確認）**:
```bash
$ bundle exec rspec
..................................................

Finished in 5.2 seconds
50 examples, 0 failures
```

#### Step 5: 実装完了報告

```markdown
## TDD実装完了: ブログ記事検索機能

### 実装したテスト

#### Model: Article
- ✅ 正常系: 5件
- ✅ 異常系: 3件
- ✅ エッジケース: 3件

#### Service: ArticleSearchService
- ✅ 正常系: 3件
- ✅ 異常系: 2件

#### Controller: SearchController
- ✅ 正常系: 2件
- ✅ 異常系: 2件

### テスト結果

```bash
$ bundle exec rspec

Finished in 8.5 seconds
20 examples, 0 failures
```

### カバレッジ

- Model: 100%
- Service: 100%
- Controller: 95%

### 実装ファイル

- `spec/models/article_spec.rb`
- `spec/services/article_search_service_spec.rb`
- `spec/controllers/search_controller_spec.rb`
- `spec/factories/articles.rb`
- `app/models/article.rb`
- `app/services/article_search_service.rb`
- `app/controllers/search_controller.rb`
```

---

### Phase 3: テスト検証（Kiro）

#### Step 1: テスト実行確認

```bash
$ bundle exec rspec
```

#### Step 2: カバレッジ確認

```bash
$ open coverage/index.html
```

#### Step 3: テスト内容確認

- [ ] テスト仕様通りのテストが実装されているか
- [ ] 正常系・異常系・エッジケースが網羅されているか
- [ ] テストが適切に失敗するか（Redの確認）
- [ ] テストが適切に成功するか（Greenの確認）

#### Step 4: 仕様書更新

```markdown
## 📊 実装履歴

| 日付 | 担当 | 内容 |
|------|------|------|
| 2025-12-27 | Kiro | テスト仕様設計 |
| 2025-12-27 | Claude Code | TDD実装完了（20テスト、カバレッジ98%） |
| 2025-12-27 | Kiro | テスト検証完了 |
```

---

## 📝 テスト仕様書テンプレート

### 基本構造

```markdown
## 🧪 テスト仕様

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Model | `app/models/xxx.rb` | `spec/models/xxx_spec.rb` |

### Model: ModelName

#### describe 'メソッド名'

**正常系**:
- [ ] テストケース1
- [ ] テストケース2

**異常系**:
- [ ] テストケース1
- [ ] テストケース2

**エッジケース**:
- [ ] テストケース1
- [ ] テストケース2

### テストコード例

```ruby
RSpec.describe ModelName, type: :model do
  describe 'メソッド名' do
    context '正常系' do
      it 'テストケース1' do
        # Arrange（準備）
        # Act（実行）
        # Assert（検証）
      end
    end
  end
end
```

### テストデータ（FactoryBot）

```ruby
FactoryBot.define do
  factory :model_name do
    # 属性定義
  end
end
```
```

---

## 🎯 テストケース設計のコツ

### 1. AAA（Arrange-Act-Assert）パターン

```ruby
it 'キーワードで検索できる' do
  # Arrange: テストデータ準備
  article = create(:article, title: 'Ruby on Rails')
  
  # Act: 実行
  result = Article.search_by_keyword('Rails')
  
  # Assert: 検証
  expect(result).to include(article)
end
```

### 2. 境界値テスト

```ruby
describe 'バリデーション' do
  it '最小文字数（1文字）で保存できる' do
    article = build(:article, title: 'a')
    expect(article).to be_valid
  end
  
  it '最大文字数（100文字）で保存できる' do
    article = build(:article, title: 'a' * 100)
    expect(article).to be_valid
  end
  
  it '最大文字数超過（101文字）で保存できない' do
    article = build(:article, title: 'a' * 101)
    expect(article).not_to be_valid
  end
end
```

### 3. エッジケース

```ruby
describe '特殊文字の扱い' do
  it 'SQLワイルドカード（%）をエスケープする' do
    article = create(:article, title: '100%達成')
    result = Article.search_by_keyword('100%')
    expect(result).to include(article)
  end
  
  it 'SQLワイルドカード（_）をエスケープする' do
    article = create(:article, title: 'test_data')
    result = Article.search_by_keyword('test_')
    expect(result).to include(article)
  end
end
```

### 4. モック・スタブの活用

```ruby
describe '外部API呼び出し' do
  it 'AWS SESでメール送信する' do
    # モック作成
    ses_client = instance_double(Aws::SES::Client)
    allow(Aws::SES::Client).to receive(:new).and_return(ses_client)
    allow(ses_client).to receive(:send_email).and_return(true)
    
    # 実行
    service = EmailService.new
    result = service.send_email('test@example.com', 'Subject', 'Body')
    
    # 検証
    expect(result).to be true
    expect(ses_client).to have_received(:send_email)
  end
end
```

---

## 📊 カバレッジ目標

| 対象 | 目標カバレッジ |
|------|---------------|
| Model | 95%以上 |
| Service | 95%以上 |
| Controller | 90%以上 |
| Helper | 80%以上 |

---

## 🔧 テスト実行コマンド

### 全テスト実行
```bash
$ bundle exec rspec
```

### 特定ファイルのテスト実行
```bash
$ bundle exec rspec spec/models/article_spec.rb
```

### 特定の行のテスト実行
```bash
$ bundle exec rspec spec/models/article_spec.rb:10
```

### カバレッジ確認
```bash
$ bundle exec rspec
$ open coverage/index.html
```

---

## 📌 重要な原則

1. **テストファースト**: 実装前に必ずテストを書く
2. **Red-Green-Refactor**: TDDサイクルを守る
3. **1テスト1検証**: 1つのテストで1つのことだけを検証
4. **独立性**: テスト間で依存関係を持たない
5. **高速性**: テストは高速に実行できるようにする

---

**作成者**: Kiro  
**作成日**: 2025-12-27  
**バージョン**: 1.0
