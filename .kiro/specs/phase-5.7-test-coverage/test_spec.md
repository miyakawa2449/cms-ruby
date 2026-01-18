# Phase 5.7: テストカバレッジ向上 - テスト仕様書

**Phase**: 5.7  
**機能名**: テストカバレッジ向上  
**作成日**: 2026-01-18  
**作成者**: Kiro

---

## 📋 テスト一覧

### ユニットテスト（75件）

#### AI機能テスト（60件）
- TitleSuggester: 10件
- SummaryGenerator: 10件
- TagSuggester: 10件
- SlugGenerator: 10件
- SeoMetaGenerator: 10件
- StructureSuggester: 10件

#### AI基盤テスト（20件）
- BedrockClient: 10件
- UsageTracker: 5件
- ModelSelector: 5件

### 統合テスト（60件）

#### 記事CRUD（20件）
- 作成フロー: 5件
- 編集フロー: 5件
- 削除フロー: 5件
- 公開フロー: 5件

#### 認証・認可（15件）
- ログイン・ログアウト: 5件
- アクセス拒否: 5件
- セッション管理: 5件

#### APIエンドポイント（25件）
- 記事API: 10件
- カテゴリAPI: 5件
- タグAPI: 5件
- AI API: 5件

### E2Eテスト（15件）

#### 記事作成フロー（10件）
- 記事作成: 5件
- AI機能使用: 5件

#### 画像・メディア（5件）
- 画像アップロード: 3件
- メディアライブラリ: 2件

---

## 🎯 カバレッジ目標

| カテゴリ | 目標 | テスト数 |
|---------|------|---------|
| ユニットテスト | 90%以上 | 75件 |
| 統合テスト | 80%以上 | 60件 |
| E2Eテスト | 主要フロー | 15件 |
| **合計** | **85%以上** | **150件** |

---

## 🧪 主要テストケース

### 1. TitleSuggesterテスト

```ruby
RSpec.describe Ai::TitleSuggester do
  # 1. 正常系: タイトル提案成功
  # 2. 異常系: API エラー
  # 3. 異常系: タイムアウト
  # 4. プロンプト生成の正確性
  # 5. レスポンスパースの正確性
  # 6. 使用量トラッキング
  # 7. モデル選択の正確性
  # 8. エラーログ出力
  # 9. リトライ機能
  # 10. キャッシュ機能
end
```

### 2. 記事CRUD全フローテスト

```ruby
RSpec.describe 'Articles Full Flow', type: :request do
  # 1. 記事作成 → AI機能 → 保存
  # 2. 記事編集 → カテゴリ変更 → 更新
  # 3. 記事削除 → キャッシュ無効化
  # 4. 記事公開 → フロントエンド表示
  # 5. 下書き保存 → 公開 → 非公開
end
```

### 3. 記事作成フローE2Eテスト

```ruby
RSpec.describe 'Article Creation Flow', type: :system do
  # 1. ログイン → 記事作成ページ
  # 2. タイトル提案 → 適用
  # 3. 要約生成 → 適用
  # 4. タグ提案 → 適用
  # 5. 保存 → 確認
end
```

---

## 📊 テスト実行

### 全テスト実行

```bash
# 全テスト
bundle exec rspec

# カバレッジ測定
COVERAGE=true bundle exec rspec

# ユニットテストのみ
bundle exec rspec spec/services spec/models

# 統合テストのみ
bundle exec rspec spec/requests

# E2Eテストのみ
bundle exec rspec spec/system
```

### CI/CD統合

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16-alpine
      redis:
        image: redis:7.4.1-alpine
    
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.7
          bundler-cache: true
      
      - name: Setup Database
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load
      
      - name: Run Tests
        run: bundle exec rspec
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.json
```

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**ステータス**: レビュー待ち
