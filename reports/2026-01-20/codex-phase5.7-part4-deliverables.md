# Phase 5.7 テストカバレッジ向上 - Part 4: 成果物・注意事項

---

## ✅ Task 10: Final Integration and Coverage

### 10.1 SimpleCov設定

**ファイル**: `spec/spec_helper.rb`（先頭に追加）

```ruby
if ENV['COVERAGE']
  require 'simplecov'
  
  SimpleCov.start 'rails' do
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/vendor/'
    add_filter '/db/'

    add_group 'Models', 'app/models'
    add_group 'Controllers', 'app/controllers'
    add_group 'Services', 'app/services'
    add_group 'Helpers', 'app/helpers'
    add_group 'Jobs', 'app/jobs'
    add_group 'Mailers', 'app/mailers'

    minimum_coverage 85
    minimum_coverage_by_file 70
  end
end
```

### 10.2 全テスト実行・カバレッジ測定

```bash
# カバレッジ測定付きで全テスト実行
COVERAGE=true bundle exec rspec

# カバレッジレポート確認
open coverage/index.html
```

### 10.3 カバレッジ85%達成確認

**確認項目**:
- [ ] 全体カバレッジ: 85%以上
- [ ] Models: 90%以上
- [ ] Controllers: 80%以上
- [ ] Services: 90%以上
- [ ] Helpers: 80%以上

### 10.4 CI/CD統合（GitHub Actions）

**ファイル**: `.github/workflows/test.yml`

```yaml
name: Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: portfolio_rb_test
          POSTGRES_USER: portfolio
          POSTGRES_PASSWORD: portfolio_password
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7.4.1-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.7
          bundler-cache: true
      
      - name: Setup Database
        env:
          RAILS_ENV: test
          DATABASE_URL: postgresql://portfolio:portfolio_password@localhost:5432/portfolio_rb_test
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load
      
      - name: Run Tests
        env:
          RAILS_ENV: test
          DATABASE_URL: postgresql://portfolio:portfolio_password@localhost:5432/portfolio_rb_test
          REDIS_URL: redis://localhost:6379/0
          COVERAGE: true
        run: bundle exec rspec
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.json
          fail_ci_if_error: true
```

---

## 📊 成果物

作業完了後、以下のレポートを作成してください：

### レポートファイル: `reports/2026-01-20/codex-phase5.7-report.md`

**含めるべき内容**:

1. **テスト実行結果**
   - 作成したテストファイルの一覧（150件）
   - テスト実行結果（成功/失敗の数）
   - 失敗したテストの詳細と原因

2. **カバレッジ測定結果**
   - 全体カバレッジ（目標: 85%以上）
   - カテゴリ別カバレッジ
   - カバレッジが低いファイルのリスト

3. **テスト実行時間**
   - ユニットテスト: X分
   - 統合テスト: X分
   - E2Eテスト: X分
   - 合計: X分（目標: 30分以内）

4. **問題点の洗い出し**
   - 発見したバグや問題
   - テストが書けなかった箇所
   - カバレッジ目標未達成の理由

5. **改善提案**
   - テストの追加が必要な箇所
   - リファクタリングが必要な箇所
   - CI/CD改善提案

---

## ⚠️ 重要な注意事項

### 1. モック戦略

**BedrockClient（外部API）は必ずモック化**:
```ruby
let(:bedrock_client) { instance_double(Ai::BedrockClient) }

before do
  allow(Ai::BedrockClient).to receive(:new).and_return(bedrock_client)
  allow(bedrock_client).to receive(:generate).and_return(mock_response)
end
```

**理由**:
- 外部APIへの実際のリクエストを避ける
- テスト実行時間の短縮
- テストの安定性向上

### 2. テストデータ

**FactoryBotを活用**:
```ruby
# 基本的な使用
article = create(:article, :published)

# 関連データ付き
article = create(:article, :with_categories, :with_tags)

# 複数作成
articles = create_list(:article, 5, :published)
```

### 3. E2Eテストの注意点

**待機時間の設定**:
```ruby
# JavaScriptの実行を待つ
expect(page).to have_css('.loading-indicator', wait: 10)

# 要素が消えるまで待つ
expect(page).not_to have_css('.loading-indicator', wait: 10)
```

**スクリーンショット**:
```ruby
# テスト失敗時に自動保存
config.after(:each, type: :system) do |example|
  if example.exception
    take_screenshot
  end
end
```

### 4. テスト実行環境

**Docker環境での実行**:
```bash
# Dockerコンテナ内で実行
docker-compose exec web bundle exec rspec

# または
docker-compose run --rm web bundle exec rspec
```

**ローカル環境での実行**:
```bash
# PostgreSQLとRedisが起動していることを確認
docker-compose up -d db redis

# テスト実行
RAILS_ENV=test bundle exec rspec
```

---

## 🎯 成功基準

以下の条件を満たせば作業完了とします：

1. ✅ **150件以上のテストケースを作成**
2. ✅ **テストカバレッジ85%以上を達成**
3. ✅ **テスト実行時間30分以内**
4. ✅ **テスト成功率95%以上**（失敗は5%以内）
5. ✅ **CI/CD統合完了**（GitHub Actions設定）
6. ✅ **レポート作成完了**

---

## 📝 質問・相談事項

作業中に以下のような状況が発生した場合は、人に確認してください：

### 1. テストが大量に失敗する場合
- 実装に重大なバグがある可能性
- モック戦略の見直しが必要
- 仕様の解釈が間違っている可能性

### 2. カバレッジ目標を大幅に下回る場合
- テストの追加が必要
- 実装の見直しが必要
- 目標値の再検討が必要

### 3. E2Eテストが不安定な場合
- Selenium WebDriverの設定見直し
- 待機時間の調整
- テストシナリオの簡略化

### 4. テスト実行時間が30分を大幅に超える場合
- テストの並列実行を検討
- E2Eテストの削減を検討
- モック化の強化

---

## 📅 作業期限

**推奨作業時間**: 2-3日（Phase 5.6の実績を踏まえて）  
**期限**: 2026-01-22（2日後）

---

## 🎉 Phase 5.6での成功を再現しよう

Phase 5.6でのCodexの成果：
- ✅ 42件のテスト作成（すべて成功）
- ✅ フラグメントキャッシュの実装追加
- ✅ 問題発見と主体的な解決
- ✅ Kiroから5/5の評価

**Phase 5.7でも同様の成功を期待しています！**

---

**作成者**: Kiro（仕様管理担当）  
**作成日**: 2026-01-20  
**Phase**: 5.7 テストカバレッジ向上
