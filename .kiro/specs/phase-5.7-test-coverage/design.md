# Phase 5.7: テストカバレッジ向上 - 設計書

**Phase**: 5.7  
**機能名**: テストカバレッジ向上  
**作成日**: 2026-01-18  
**作成者**: Kiro

---

## 📋 テスト戦略

### テストピラミッド

```
        /\
       /E2E\          10% - 15テスト
      /------\
     /統合テスト\      30% - 60テスト
    /----------\
   /ユニットテスト\    60% - 75テスト
  /--------------\
```

### カバレッジ目標

| カテゴリ | 目標 | テスト数 |
|---------|------|---------|
| ユニットテスト | 90%以上 | 75件 |
| 統合テスト | 80%以上 | 60件 |
| E2Eテスト | 主要フロー | 15件 |
| **合計** | **85%以上** | **150件** |

---

## 🧪 AI機能テスト設計

### 1. TitleSuggesterテスト

```ruby
# spec/services/ai/title_suggester_spec.rb
require 'rails_helper'

RSpec.describe Ai::TitleSuggester do
  let(:article) { create(:article, content: 'テスト記事の内容') }
  let(:suggester) { described_class.new(article: article) }

  before do
    # BedrockClientをモック化
    allow_any_instance_of(Ai::BedrockClient).to receive(:invoke).and_return({
      content: "わかりやすいタイトル\nSNS映えタイトル",
      input_tokens: 100,
      output_tokens: 50
    })
  end

  describe '#suggest' do
    it 'returns two title suggestions' do
      result = suggester.suggest
      
      expect(result).to be_a(Hash)
      expect(result[:clear]).to eq('わかりやすいタイトル')
      expect(result[:catchy]).to eq('SNS映えタイトル')
    end

    it 'tracks usage' do
      expect {
        suggester.suggest
      }.to change { AiGeneration.count }.by(1)
    end

    it 'handles API errors gracefully' do
      allow_any_instance_of(Ai::BedrockClient).to receive(:invoke).and_raise(
        Ai::BedrockApiError, 'API error'
      )

      expect {
        suggester.suggest
      }.to raise_error(Ai::BedrockApiError)
    end
  end

  describe '#build_prompt' do
    it 'includes article content' do
      prompt = suggester.send(:build_prompt)
      
      expect(prompt).to include('テスト記事の内容')
    end

    it 'includes instructions' do
      prompt = suggester.send(:build_prompt)
      
      expect(prompt).to include('タイトル')
      expect(prompt).to include('2種類')
    end
  end
end
```

### 2. BedrockClientモックテスト

```ruby
# spec/services/ai/bedrock_client_spec.rb
require 'rails_helper'

RSpec.describe Ai::BedrockClient do
  let(:client) { described_class.new }

  describe '#invoke' do
    context 'when API call succeeds' do
      before do
        stub_request(:post, /bedrock-runtime/)
          .to_return(
            status: 200,
            body: {
              content: [{ text: 'AI response' }],
              usage: { input_tokens: 100, output_tokens: 50 }
            }.to_json
          )
      end

      it 'returns parsed response' do
        result = client.invoke(model_id: 'test-model', prompt: 'test')
        
        expect(result[:content]).to eq('AI response')
        expect(result[:input_tokens]).to eq(100)
        expect(result[:output_tokens]).to eq(50)
      end
    end

    context 'when API call times out' do
      before do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      end

      it 'raises BedrockTimeoutError' do
        expect {
          client.invoke(model_id: 'test-model', prompt: 'test')
        }.to raise_error(Ai::BedrockTimeoutError)
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:post, /bedrock-runtime/)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'retries and raises BedrockApiError' do
        expect {
          client.invoke(model_id: 'test-model', prompt: 'test')
        }.to raise_error(Ai::BedrockApiError)
      end
    end
  end
end
```

---

## 🔗 統合テスト設計

### 1. 記事CRUD全フローテスト

```ruby
# spec/requests/admin/articles_full_flow_spec.rb
require 'rails_helper'

RSpec.describe 'Articles Full Flow', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user
  end

  describe 'Create → AI → Save → Publish → View' do
    it 'completes full article creation flow' do
      # 1. 記事作成ページ表示
      get new_admin_article_path
      expect(response).to have_http_status(:success)

      # 2. AI機能でタイトル提案
      post admin_ai_suggest_title_path, params: {
        content: 'テスト記事の内容'
      }, as: :json
      expect(response).to have_http_status(:success)
      title_data = JSON.parse(response.body)

      # 3. 記事作成
      expect {
        post admin_articles_path, params: {
          article: {
            title: title_data['clear'],
            content: 'テスト記事の内容',
            status: 'draft'
          }
        }
      }.to change { Article.count }.by(1)

      article = Article.last
      expect(response).to redirect_to(edit_admin_article_path(article))

      # 4. 記事公開
      patch admin_article_path(article), params: {
        article: { status: 'published' }
      }
      expect(article.reload.status).to eq('published')

      # 5. フロントエンドで表示確認
      get blog_article_path(article.slug)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(article.title)
    end
  end
end
```

---

## 🖥️ E2Eテスト設計

### 1. Capybara設定

```ruby
# spec/support/capybara.rb
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

Capybara.default_driver = :selenium_headless
Capybara.javascript_driver = :selenium_headless
Capybara.default_max_wait_time = 5

# スクリーンショット設定
Capybara.save_path = Rails.root.join('tmp/capybara')
```

### 2. 記事作成フローE2Eテスト

```ruby
# spec/system/article_creation_flow_spec.rb
require 'rails_helper'

RSpec.describe 'Article Creation Flow', type: :system do
  let(:admin_user) { create(:admin_user) }

  before do
    driven_by(:selenium_headless)
    login_as(admin_user, scope: :admin_user)
  end

  it 'creates article with AI assistance' do
    visit new_admin_article_path

    # タイトル入力
    fill_in 'article_content', with: 'テスト記事の内容'

    # AI機能でタイトル提案
    click_button 'タイトルを提案'
    
    # ローディング待機
    expect(page).to have_content('生成中', wait: 2)
    expect(page).to have_content('わかりやすいタイトル', wait: 10)

    # タイトル適用
    within '#title-suggestions' do
      first('.apply-title').click
    end

    # 記事保存
    click_button '保存'

    expect(page).to have_content('記事を作成しました')
    expect(Article.last.title).to be_present
  end
end
```

---

## 📊 SimpleCov設定

```ruby
# spec/spec_helper.rb
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

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**ステータス**: レビュー待ち
