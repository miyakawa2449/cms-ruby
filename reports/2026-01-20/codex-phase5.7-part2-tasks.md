# Phase 5.7 テストカバレッジ向上 - Part 2: 詳細タスク

---

## ✅ Task 1: Setup and Dependencies

### 1.1 Gem のインストール

```ruby
# Gemfile に追加（test グループ）
group :test do
  gem 'capybara', '~> 3.39'
  gem 'selenium-webdriver', '~> 4.15'
  gem 'webmock', '~> 3.19'
  gem 'simplecov', '~> 0.22', require: false
end
```

**実行コマンド**:
```bash
bundle install
```

### 1.2 Capybara 設定

**ファイル**: `spec/support/capybara.rb`

```ruby
require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1920,1080')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_headless
Capybara.default_max_wait_time = 5
```

### 1.3 SimpleCov 設定

**ファイル**: `spec/support/simplecov.rb`

```ruby
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Helpers', 'app/helpers'
  add_group 'Jobs', 'app/jobs'

  minimum_coverage 85
  minimum_coverage_by_file 70
end
```

### 1.4 WebMock 設定

**ファイル**: `spec/support/webmock.rb`

```ruby
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)
```

---

## ✅ Task 2-3: AI機能ユニットテスト（60件）

### テスト戦略

**モック対象**: BedrockClient（外部API依存を排除）

**共通テスト項目**（各Suggester/Generator）:
1. 正常系: 成功レスポンス
2. 異常系: APIエラー
3. 異常系: タイムアウト
4. 異常系: ネットワークエラー
5. プロンプト生成の正確性
6. レスポンスパースの正確性
7. 使用量トラッキング
8. モデル選択の正確性
9. エラーログ出力
10. リトライ機能

### 実装例: TitleSuggester

**ファイル**: `spec/services/ai/title_suggester_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Ai::TitleSuggester do
  let(:article) { create(:article, content: "Sample content") }
  let(:bedrock_client) { instance_double(Ai::BedrockClient) }
  let(:suggester) { described_class.new(article) }

  before do
    allow(Ai::BedrockClient).to receive(:new).and_return(bedrock_client)
  end

  describe '#suggest' do
    context '正常系' do
      it 'タイトル提案が成功する' do
        response = { titles: ["Title 1", "Title 2", "Title 3"] }
        allow(bedrock_client).to receive(:generate).and_return(response)

        result = suggester.suggest

        expect(result).to be_success
        expect(result.titles).to eq(["Title 1", "Title 2", "Title 3"])
      end
    end

    context '異常系' do
      it 'APIエラー時にエラーを返す' do
        allow(bedrock_client).to receive(:generate)
          .and_raise(Ai::BedrockClient::ApiError, "API Error")

        result = suggester.suggest

        expect(result).to be_failure
        expect(result.error).to include("API Error")
      end

      it 'タイムアウト時にエラーを返す' do
        allow(bedrock_client).to receive(:generate)
          .and_raise(Timeout::Error)

        result = suggester.suggest

        expect(result).to be_failure
        expect(result.error).to include("timeout")
      end
    end

    # 残り7件のテストを実装...
  end
end
```

**同様のパターンで以下を実装**:
- SummaryGenerator（10件）
- TagSuggester（10件）
- SlugGenerator（10件）
- SeoMetaGenerator（10件）
- StructureSuggester（10件）

---

## ✅ Task 4: AI基盤テスト（15件）

### BedrockClient テスト

**ファイル**: `spec/services/ai/bedrock_client_spec.rb`

**テスト項目**:
1. 正常系: 成功レスポンス
2. 異常系: 400エラー
3. 異常系: 500エラー
4. 異常系: タイムアウト
5. 異常系: ネットワークエラー
6. リトライ機能（最大3回）
7. 指数バックオフ
8. エラーログ出力
9. トークン使用量計測
10. レスポンスパース

### UsageTracker テスト

**ファイル**: `spec/services/ai/usage_tracker_spec.rb`

**テスト項目**:
1. 使用量記録
2. 統計情報取得
3. 日別集計
4. 月別集計
5. コスト計算

---

次のファイル: Part 3 - 統合テスト・E2Eテスト
