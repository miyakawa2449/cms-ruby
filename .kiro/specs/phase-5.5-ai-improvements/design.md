# Phase 5.5: AI機能改善 - 設計書

**Phase**: 5.5  
**機能名**: AI機能改善  
**作成日**: 2026-01-18  
**作成者**: Kiro

---

## 📋 目次

1. [アーキテクチャ設計](#アーキテクチャ設計)
2. [データモデル設計](#データモデル設計)
3. [サービスクラス設計](#サービスクラス設計)
4. [コントローラー設計](#コントローラー設計)
5. [ビュー設計](#ビュー設計)
6. [API設計](#api設計)
7. [フロントエンド設計](#フロントエンド設計)
8. [正確性プロパティ](#正確性プロパティ)

---

## 🏗️ アーキテクチャ設計

### システム構成図

```
┌─────────────────────────────────────────────────────────┐
│                    管理画面UI                            │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │ 記事編集画面      │  │ AI使用統計ページ          │    │
│  │ - 構成提案ボタン  │  │ - 日別/月別グラフ         │    │
│  │ - トピック入力    │  │ - 機能別使用量           │    │
│  └──────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Stimulusコントローラー                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │ ai_assistant_controller.js                        │  │
│  │ - suggestStructure()                             │  │
│  │ - displayStructure()                             │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Railsコントローラー                    │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │ Admin::AiController│ │ Admin::AiUsageController │    │
│  │ - suggest_structure│ │ - index                  │    │
│  └──────────────────┘  │ - export                 │    │
│                        └──────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    サービスレイヤー                       │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │ AI::StructureSuggester│ │ AI::UsageStatisticsService│ │
│  │ AI::TitleSuggester   │ │ - daily_usage()          │ │
│  │ AI::SummaryGenerator │ │ - monthly_usage()        │ │
│  │ AI::TagSuggester     │ │ - usage_by_feature()     │ │
│  │ AI::SlugGenerator    │ │ - total_cost()           │ │
│  │ AI::SeoMetaGenerator │ └──────────────────────────┘ │
│  └──────────────────┘                                   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    基盤サービス                          │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │ AI::BedrockClient │  │ AI::UsageTracker         │    │
│  │ - invoke()        │  │ - track()                │    │
│  │ - retry_logic()   │  └──────────────────────────┘    │
│  └──────────────────┘                                   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    データベース                          │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │ ai_generations   │  │ ai_usage_stats           │    │
│  └──────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Amazon Bedrock API                      │
│  - Claude 3.5 Sonnet                                    │
│  - Claude 3 Haiku                                       │
└─────────────────────────────────────────────────────────┘
```


### レイヤー構成

| レイヤー | 責務 | 主要コンポーネント |
|---------|------|------------------|
| **プレゼンテーション** | UI表示・ユーザー操作 | ERBビュー、Stimulusコントローラー |
| **コントローラー** | リクエスト処理・レスポンス生成 | Admin::AiController, Admin::AiUsageController |
| **サービス** | ビジネスロジック | StructureSuggester, UsageStatisticsService |
| **基盤** | 外部API連携・共通機能 | BedrockClient, UsageTracker |
| **データ** | データ永続化 | AiGeneration, AiUsageStat |

---

## 📊 データモデル設計

### 既存モデル（変更なし）

#### AiGeneration
```ruby
# app/models/ai_generation.rb
class AiGeneration < ApplicationRecord
  belongs_to :article, optional: true

  validates :feature_type, presence: true
  validates :model_name, presence: true
  validates :input_tokens, numericality: { greater_than_or_equal_to: 0 }
  validates :output_tokens, numericality: { greater_than_or_equal_to: 0 }

  # feature_type: title, summary, tags, slug, seo_meta, structure
  enum feature_type: {
    title: 'title',
    summary: 'summary',
    tags: 'tags',
    slug: 'slug',
    seo_meta: 'seo_meta',
    structure: 'structure'  # 新規追加
  }
end
```

#### AiUsageStat
```ruby
# app/models/ai_usage_stat.rb
class AiUsageStat < ApplicationRecord
  validates :date, presence: true
  validates :feature_type, presence: true
  validates :model_name, presence: true

  # 日次集計用スコープ
  scope :for_date_range, ->(start_date, end_date) {
    where(date: start_date..end_date)
  }

  scope :for_feature, ->(feature_type) {
    where(feature_type: feature_type)
  }

  # 集計メソッド
  def self.aggregate_daily(date)
    # 日次集計ロジック（既存）
  end
end
```

---

## 🔧 サービスクラス設計

### 1. AI::StructureSuggester（既存 - プロンプト改善）

```ruby
# app/services/ai/structure_suggester.rb
module Ai
  class StructureSuggester
    def initialize(topic:, article: nil)
      @topic = topic
      @article = article
      @bedrock_client = BedrockClient.new
      @model_selector = ModelSelector.new
      @usage_tracker = UsageTracker.new
    end

    def suggest
      model = @model_selector.select_model(:structure)
      prompt = build_prompt

      response = @bedrock_client.invoke(
        model_id: model[:id],
        prompt: prompt,
        max_tokens: 2000
      )

      structure = parse_response(response)

      @usage_tracker.track(
        feature_type: 'structure',
        model_name: model[:name],
        prompt: prompt,
        response: structure,
        input_tokens: response[:input_tokens],
        output_tokens: response[:output_tokens],
        article_id: @article&.id
      )

      structure
    end

    private

    def build_prompt
      <<~PROMPT
        あなたは経験豊富なブログ記事の編集者です。
        以下のトピックについて、読者にとって分かりやすく、SEOにも効果的な記事構成を提案してください。

        【トピック】
        #{@topic}

        【要件】
        - H2レベルの大見出し（##）を3〜5個提案してください
        - 各大見出しの下に、H3レベルの小見出し（###）を2〜3個提案してください
        - 見出しは具体的で、読者の疑問に答える形にしてください
        - SEOキーワードを自然に含めてください
        - 論理的な流れを意識してください

        【出力形式】
        Markdown形式で見出しのみを出力してください。
        説明文は不要です。

        【出力例】
        ## 〇〇とは？基本を理解しよう
        ### 〇〇の定義
        ### 〇〇が注目される理由
        ### 〇〇の歴史

        ## 〇〇のメリット・デメリット
        ### 〇〇の3つのメリット
        ### 〇〇のデメリットと対策

        それでは、上記のトピックについて記事構成を提案してください。
      PROMPT
    end

    def parse_response(response)
      # レスポンスから構成を抽出
      response[:content].strip
    end
  end
end
```


### 2. AI::UsageStatisticsService（新規作成）

```ruby
# app/services/ai/usage_statistics_service.rb
module Ai
  class UsageStatisticsService
    # 日別使用量
    def daily_usage(start_date, end_date)
      AiUsageStat
        .for_date_range(start_date, end_date)
        .group(:date)
        .sum(:total_input_tokens, :total_output_tokens, :total_cost_usd)
        .map do |date, stats|
          {
            date: date,
            input_tokens: stats[:total_input_tokens],
            output_tokens: stats[:total_output_tokens],
            cost_usd: stats[:total_cost_usd]
          }
        end
    end

    # 月別使用量
    def monthly_usage(year, month)
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
      daily_usage(start_date, end_date)
    end

    # 機能別使用量
    def usage_by_feature(start_date, end_date)
      AiUsageStat
        .for_date_range(start_date, end_date)
        .group(:feature_type)
        .sum(:request_count, :total_input_tokens, :total_output_tokens, :total_cost_usd)
        .map do |feature_type, stats|
          {
            feature_type: feature_type,
            request_count: stats[:request_count],
            input_tokens: stats[:total_input_tokens],
            output_tokens: stats[:total_output_tokens],
            cost_usd: stats[:total_cost_usd]
          }
        end
    end

    # 総コスト
    def total_cost(start_date, end_date)
      AiUsageStat
        .for_date_range(start_date, end_date)
        .sum(:total_cost_usd)
    end

    # 使用量ランキング
    def top_features(limit = 5)
      AiUsageStat
        .group(:feature_type)
        .sum(:request_count)
        .sort_by { |_, count| -count }
        .first(limit)
        .map do |feature_type, count|
          {
            feature_type: feature_type,
            request_count: count
          }
        end
    end

    # CSVエクスポート用データ
    def export_data(start_date, end_date)
      AiGeneration
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        .order(created_at: :desc)
        .select(
          :id,
          :feature_type,
          :model_name,
          :input_tokens,
          :output_tokens,
          :cost_usd,
          :created_at
        )
    end
  end
end
```

### 3. AI::BedrockClient（既存 - リトライ機能追加）

```ruby
# app/services/ai/bedrock_client.rb
module Ai
  class BedrockClient
    MAX_RETRIES = 3
    RETRY_DELAY = 1 # 秒
    TIMEOUT = 30 # 秒

    def invoke(model_id:, prompt:, max_tokens: 1000)
      retries = 0

      begin
        Timeout.timeout(TIMEOUT) do
          response = bedrock_runtime_client.invoke_model(
            model_id: model_id,
            body: build_request_body(prompt, max_tokens).to_json,
            content_type: 'application/json',
            accept: 'application/json'
          )

          parse_response(response)
        end
      rescue Timeout::Error => e
        Rails.logger.error "[BedrockClient] Timeout: #{e.message}"
        raise BedrockTimeoutError, "AI APIがタイムアウトしました。もう一度お試しください。"
      rescue Aws::BedrockRuntime::Errors::ServiceError => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn "[BedrockClient] Retry #{retries}/#{MAX_RETRIES}: #{e.message}"
          sleep(RETRY_DELAY * retries) # 指数バックオフ
          retry
        else
          Rails.logger.error "[BedrockClient] Max retries exceeded: #{e.message}"
          raise BedrockApiError, "AI APIでエラーが発生しました。しばらくしてからお試しください。"
        end
      rescue StandardError => e
        Rails.logger.error "[BedrockClient] Unexpected error: #{e.message}"
        raise BedrockApiError, "予期しないエラーが発生しました。"
      end
    end

    private

    def bedrock_runtime_client
      @bedrock_runtime_client ||= Aws::BedrockRuntime::Client.new(
        region: ENV['AWS_REGION'] || 'us-east-1'
      )
    end

    def build_request_body(prompt, max_tokens)
      {
        anthropic_version: 'bedrock-2023-05-31',
        max_tokens: max_tokens,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ]
      }
    end

    def parse_response(response)
      body = JSON.parse(response.body.read)
      {
        content: body.dig('content', 0, 'text'),
        input_tokens: body.dig('usage', 'input_tokens'),
        output_tokens: body.dig('usage', 'output_tokens')
      }
    end
  end

  # カスタム例外
  class BedrockApiError < StandardError; end
  class BedrockTimeoutError < StandardError; end
end
```

---

## 🎮 コントローラー設計

### 1. Admin::AiController（既存 - アクション追加）

```ruby
# app/controllers/admin/ai_controller.rb
class Admin::AiController < Admin::BaseController
  before_action :authenticate_admin_user!

  # 既存アクション: suggest_title, generate_summary, suggest_tags, generate_slug, generate_seo_meta

  # 新規アクション: 記事構成提案
  def suggest_structure
    topic = params[:topic]

    if topic.blank?
      render json: { error: 'トピックを入力してください' }, status: :unprocessable_entity
      return
    end

    article = Article.find_by(id: params[:article_id])
    suggester = Ai::StructureSuggester.new(topic: topic, article: article)

    begin
      structure = suggester.suggest
      render json: { structure: structure }
    rescue Ai::BedrockTimeoutError => e
      render json: { error: e.message }, status: :request_timeout
    rescue Ai::BedrockApiError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue StandardError => e
      Rails.logger.error "[AiController] suggest_structure error: #{e.message}"
      render json: { error: '構成提案の生成に失敗しました' }, status: :internal_server_error
    end
  end
end
```

### 2. Admin::AiUsageController（新規作成）

```ruby
# app/controllers/admin/ai_usage_controller.rb
class Admin::AiUsageController < Admin::BaseController
  before_action :authenticate_admin_user!

  def index
    @statistics_service = Ai::UsageStatisticsService.new

    # 期間フィルター
    @period = params[:period] || 'month'
    @start_date, @end_date = calculate_date_range(@period)

    # 統計データ
    @daily_usage = @statistics_service.daily_usage(@start_date, @end_date)
    @usage_by_feature = @statistics_service.usage_by_feature(@start_date, @end_date)
    @total_cost = @statistics_service.total_cost(@start_date, @end_date)
    @top_features = @statistics_service.top_features(5)

    # サマリー
    @total_requests = @usage_by_feature.sum { |f| f[:request_count] }
    @total_tokens = @usage_by_feature.sum { |f| f[:input_tokens] + f[:output_tokens] }
  end

  def export
    @statistics_service = Ai::UsageStatisticsService.new
    @start_date, @end_date = calculate_date_range(params[:period] || 'month')

    data = @statistics_service.export_data(@start_date, @end_date)

    respond_to do |format|
      format.csv do
        send_data generate_csv(data),
                  filename: "ai_usage_#{@start_date}_#{@end_date}.csv",
                  type: 'text/csv'
      end
    end
  end

  private

  def calculate_date_range(period)
    case period
    when 'today'
      [Date.today, Date.today]
    when 'week'
      [Date.today.beginning_of_week, Date.today.end_of_week]
    when 'month'
      [Date.today.beginning_of_month, Date.today.end_of_month]
    when 'custom'
      [Date.parse(params[:start_date]), Date.parse(params[:end_date])]
    else
      [Date.today.beginning_of_month, Date.today.end_of_month]
    end
  end

  def generate_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << ['ID', '機能', 'モデル', '入力トークン', '出力トークン', 'コスト(USD)', '作成日時']
      data.each do |record|
        csv << [
          record.id,
          record.feature_type,
          record.model_name,
          record.input_tokens,
          record.output_tokens,
          record.cost_usd,
          record.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end
end
```


---

## 🎨 ビュー設計

### 1. 記事編集画面 - 構成提案セクション

```erb
<!-- app/views/admin/articles/_form.html.erb -->
<!-- 既存のAI支援セクションに追加 -->

<div class="bg-white rounded-lg shadow p-6 mb-6">
  <h3 class="text-lg font-semibold mb-4">📝 記事構成提案</h3>
  
  <div data-controller="ai-assistant" data-ai-assistant-article-id-value="<%= @article.id %>">
    <!-- トピック入力 -->
    <div class="mb-4">
      <label class="block text-sm font-medium text-gray-700 mb-2">
        記事のトピック
      </label>
      <textarea
        data-ai-assistant-target="structureTopic"
        class="w-full px-3 py-2 border border-gray-300 rounded-md"
        rows="3"
        placeholder="例: Railsでのバックグラウンドジョブの実装方法"
      ></textarea>
    </div>

    <!-- 構成提案ボタン -->
    <button
      type="button"
      data-action="click->ai-assistant#suggestStructure"
      class="bg-purple-600 text-white px-4 py-2 rounded hover:bg-purple-700"
    >
      <span data-ai-assistant-target="structureButtonText">構成を提案</span>
      <span data-ai-assistant-target="structureLoading" class="hidden">
        <svg class="animate-spin h-4 w-4 inline" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        生成中...
      </span>
    </button>

    <!-- 提案結果表示 -->
    <div data-ai-assistant-target="structureResult" class="hidden mt-4">
      <div class="bg-gray-50 p-4 rounded border border-gray-200">
        <div class="flex justify-between items-start mb-2">
          <h4 class="font-medium">提案された構成</h4>
          <button
            type="button"
            data-action="click->ai-assistant#insertStructure"
            class="text-sm bg-green-600 text-white px-3 py-1 rounded hover:bg-green-700"
          >
            本文に挿入
          </button>
        </div>
        <pre data-ai-assistant-target="structureContent" class="whitespace-pre-wrap text-sm"></pre>
      </div>
    </div>

    <!-- エラー表示 -->
    <div data-ai-assistant-target="structureError" class="hidden mt-4">
      <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
        <span data-ai-assistant-target="structureErrorMessage"></span>
      </div>
    </div>
  </div>
</div>
```

### 2. AI使用統計ページ

```erb
<!-- app/views/admin/ai_usage/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">AI使用統計</h1>
    <%= link_to 'CSVエクスポート', export_admin_ai_usage_index_path(period: @period, format: :csv), 
                class: 'bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700' %>
  </div>

  <!-- 期間フィルター -->
  <div class="bg-white rounded-lg shadow p-4 mb-6">
    <div class="flex gap-2">
      <%= link_to '今日', admin_ai_usage_index_path(period: 'today'), 
                  class: "px-4 py-2 rounded #{@period == 'today' ? 'bg-blue-600 text-white' : 'bg-gray-200'}" %>
      <%= link_to '今週', admin_ai_usage_index_path(period: 'week'), 
                  class: "px-4 py-2 rounded #{@period == 'week' ? 'bg-blue-600 text-white' : 'bg-gray-200'}" %>
      <%= link_to '今月', admin_ai_usage_index_path(period: 'month'), 
                  class: "px-4 py-2 rounded #{@period == 'month' ? 'bg-blue-600 text-white' : 'bg-gray-200'}" %>
    </div>
  </div>

  <!-- サマリーカード -->
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
    <!-- 総リクエスト数 -->
    <div class="bg-white rounded-lg shadow p-6">
      <div class="text-sm text-gray-600 mb-2">総リクエスト数</div>
      <div class="text-3xl font-bold"><%= number_with_delimiter(@total_requests) %></div>
    </div>

    <!-- 総トークン数 -->
    <div class="bg-white rounded-lg shadow p-6">
      <div class="text-sm text-gray-600 mb-2">総トークン数</div>
      <div class="text-3xl font-bold"><%= number_with_delimiter(@total_tokens) %></div>
    </div>

    <!-- 推定コスト -->
    <div class="bg-white rounded-lg shadow p-6">
      <div class="text-sm text-gray-600 mb-2">推定コスト</div>
      <div class="text-3xl font-bold">$<%= number_with_precision(@total_cost, precision: 2) %></div>
    </div>
  </div>

  <!-- 日別使用量グラフ -->
  <div class="bg-white rounded-lg shadow p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4">日別使用量</h2>
    <canvas id="dailyUsageChart" height="100"></canvas>
  </div>

  <!-- 機能別使用量グラフ -->
  <div class="bg-white rounded-lg shadow p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4">機能別使用量</h2>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <canvas id="featureUsageChart"></canvas>
      <div>
        <h3 class="font-medium mb-2">使用量ランキング</h3>
        <ul class="space-y-2">
          <% @top_features.each_with_index do |feature, index| %>
            <li class="flex justify-between items-center">
              <span><%= index + 1 %>. <%= feature[:feature_type] %></span>
              <span class="font-semibold"><%= number_with_delimiter(feature[:request_count]) %>回</span>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
  </div>

  <!-- 使用履歴テーブル -->
  <div class="bg-white rounded-lg shadow p-6">
    <h2 class="text-xl font-semibold mb-4">使用履歴</h2>
    <table class="min-w-full">
      <thead>
        <tr class="border-b">
          <th class="text-left py-2">機能</th>
          <th class="text-left py-2">モデル</th>
          <th class="text-right py-2">入力トークン</th>
          <th class="text-right py-2">出力トークン</th>
          <th class="text-right py-2">コスト</th>
          <th class="text-left py-2">日時</th>
        </tr>
      </thead>
      <tbody>
        <% @usage_by_feature.each do |usage| %>
          <tr class="border-b">
            <td class="py-2"><%= usage[:feature_type] %></td>
            <td class="py-2">-</td>
            <td class="text-right py-2"><%= number_with_delimiter(usage[:input_tokens]) %></td>
            <td class="text-right py-2"><%= number_with_delimiter(usage[:output_tokens]) %></td>
            <td class="text-right py-2">$<%= number_with_precision(usage[:cost_usd], precision: 4) %></td>
            <td class="py-2">-</td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>

<script>
  // Chart.jsでグラフ描画
  document.addEventListener('DOMContentLoaded', function() {
    // 日別使用量グラフ
    const dailyCtx = document.getElementById('dailyUsageChart').getContext('2d');
    new Chart(dailyCtx, {
      type: 'line',
      data: {
        labels: <%= raw @daily_usage.map { |d| d[:date].strftime('%m/%d') }.to_json %>,
        datasets: [{
          label: 'トークン数',
          data: <%= raw @daily_usage.map { |d| d[:input_tokens] + d[:output_tokens] }.to_json %>,
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    });

    // 機能別使用量グラフ
    const featureCtx = document.getElementById('featureUsageChart').getContext('2d');
    new Chart(featureCtx, {
      type: 'doughnut',
      data: {
        labels: <%= raw @usage_by_feature.map { |f| f[:feature_type] }.to_json %>,
        datasets: [{
          data: <%= raw @usage_by_feature.map { |f| f[:request_count] }.to_json %>,
          backgroundColor: [
            'rgb(59, 130, 246)',
            'rgb(16, 185, 129)',
            'rgb(245, 158, 11)',
            'rgb(239, 68, 68)',
            'rgb(139, 92, 246)',
            'rgb(236, 72, 153)'
          ]
        }]
      },
      options: {
        responsive: true
      }
    });
  });
</script>
```


---

## 🔌 API設計

### エンドポイント一覧

| メソッド | パス | 説明 | 認証 |
|---------|------|------|------|
| POST | `/admin/ai/suggest_structure` | 記事構成提案 | 必須 |
| GET | `/admin/ai_usage` | AI使用統計ページ | 必須 |
| GET | `/admin/ai_usage/export` | CSV形式でエクスポート | 必須 |

### 1. POST /admin/ai/suggest_structure

**リクエスト**:
```json
{
  "topic": "Railsでのバックグラウンドジョブの実装方法",
  "article_id": 123  // オプション
}
```

**レスポンス（成功）**:
```json
{
  "structure": "## バックグラウンドジョブとは？\n### 定義と役割\n### 使用するケース\n\n## Sidekiqの導入\n### インストール手順\n### 基本設定"
}
```

**レスポンス（エラー）**:
```json
{
  "error": "トピックを入力してください"
}
```

**ステータスコード**:
- 200: 成功
- 422: バリデーションエラー
- 408: タイムアウト
- 503: AI APIエラー
- 500: サーバーエラー

### 2. GET /admin/ai_usage

**クエリパラメータ**:
- `period`: 期間（today, week, month, custom）
- `start_date`: 開始日（customの場合）
- `end_date`: 終了日（customの場合）

**レスポンス**: HTMLページ

### 3. GET /admin/ai_usage/export

**クエリパラメータ**:
- `period`: 期間（today, week, month, custom）
- `start_date`: 開始日（customの場合）
- `end_date`: 終了日（customの場合）

**レスポンス**: CSV形式のファイル

---

## 💻 フロントエンド設計

### Stimulusコントローラー拡張

```javascript
// app/javascript/controllers/ai_assistant_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    // 既存ターゲット
    "titleResult", "summaryResult", "tagsResult", "slugResult", "seoMetaResult",
    // 新規ターゲット
    "structureTopic", "structureResult", "structureContent", 
    "structureError", "structureErrorMessage",
    "structureButtonText", "structureLoading"
  ]

  static values = {
    articleId: Number
  }

  // 既存メソッド: suggestTitle, generateSummary, suggestTags, generateSlug, generateSeoMeta

  // 新規メソッド: 記事構成提案
  async suggestStructure(event) {
    event.preventDefault()

    const topic = this.structureTopicTarget.value.trim()

    if (!topic) {
      this.showStructureError('トピックを入力してください')
      return
    }

    // ローディング表示
    this.structureButtonTextTarget.classList.add('hidden')
    this.structureLoadingTarget.classList.remove('hidden')
    this.structureResultTarget.classList.add('hidden')
    this.structureErrorTarget.classList.add('hidden')

    try {
      const response = await fetch('/admin/ai/suggest_structure', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          topic: topic,
          article_id: this.articleIdValue
        })
      })

      const data = await response.json()

      if (response.ok) {
        this.displayStructure(data.structure)
      } else {
        this.showStructureError(data.error || '構成提案の生成に失敗しました')
      }
    } catch (error) {
      console.error('Structure suggestion error:', error)
      this.showStructureError('ネットワークエラーが発生しました')
    } finally {
      // ローディング非表示
      this.structureButtonTextTarget.classList.remove('hidden')
      this.structureLoadingTarget.classList.add('hidden')
    }
  }

  displayStructure(structure) {
    this.structureContentTarget.textContent = structure
    this.structureResultTarget.classList.remove('hidden')
  }

  insertStructure(event) {
    event.preventDefault()

    const structure = this.structureContentTarget.textContent
    const contentTextarea = document.querySelector('#article_content')

    if (contentTextarea) {
      // カーソル位置に挿入
      const cursorPos = contentTextarea.selectionStart
      const textBefore = contentTextarea.value.substring(0, cursorPos)
      const textAfter = contentTextarea.value.substring(cursorPos)

      contentTextarea.value = textBefore + '\n\n' + structure + '\n\n' + textAfter
      contentTextarea.focus()

      // 成功メッセージ
      alert('構成を本文に挿入しました')
    }
  }

  showStructureError(message) {
    this.structureErrorMessageTarget.textContent = message
    this.structureErrorTarget.classList.remove('hidden')
  }
}
```

### Chart.js統合

```javascript
// app/javascript/application.js に追加
import Chart from 'chart.js/auto'
window.Chart = Chart
```

**package.json**:
```json
{
  "dependencies": {
    "chart.js": "^4.4.0"
  }
}
```

---

## ✅ 正確性プロパティ

### Property 1: 記事構成提案の形式検証
**Validates: Requirements 1.4**

```ruby
# spec/services/ai/structure_suggester_spec.rb
RSpec.describe Ai::StructureSuggester do
  describe '#suggest' do
    it 'returns structure in Markdown format with H2 and H3 headings' do
      suggester = described_class.new(topic: 'テストトピック')
      structure = suggester.suggest

      # H2見出しが含まれる
      expect(structure).to match(/^## .+/)
      # H3見出しが含まれる
      expect(structure).to match(/^### .+/)
      # 空でない
      expect(structure).not_to be_empty
    end
  end
end
```

### Property 2: AI使用統計の集計正確性
**Validates: Requirements 2.2, 2.3**

```ruby
# spec/services/ai/usage_statistics_service_spec.rb
RSpec.describe Ai::UsageStatisticsService do
  describe '#daily_usage' do
    it 'correctly aggregates daily token usage' do
      # テストデータ作成
      create(:ai_usage_stat, date: Date.today, total_input_tokens: 100, total_output_tokens: 50)
      create(:ai_usage_stat, date: Date.today, total_input_tokens: 200, total_output_tokens: 100)

      service = described_class.new
      result = service.daily_usage(Date.today, Date.today)

      expect(result.first[:input_tokens]).to eq(300)
      expect(result.first[:output_tokens]).to eq(150)
    end
  end

  describe '#usage_by_feature' do
    it 'correctly groups usage by feature type' do
      create(:ai_usage_stat, feature_type: 'title', request_count: 10)
      create(:ai_usage_stat, feature_type: 'summary', request_count: 5)

      service = described_class.new
      result = service.usage_by_feature(Date.today.beginning_of_month, Date.today.end_of_month)

      expect(result.find { |r| r[:feature_type] == 'title' }[:request_count]).to eq(10)
      expect(result.find { |r| r[:feature_type] == 'summary' }[:request_count]).to eq(5)
    end
  end
end
```

### Property 3: BedrockClientのリトライ機能
**Validates: Requirements 3.6**

```ruby
# spec/services/ai/bedrock_client_spec.rb
RSpec.describe Ai::BedrockClient do
  describe '#invoke' do
    it 'retries up to MAX_RETRIES times on service error' do
      client = described_class.new
      allow(client).to receive(:bedrock_runtime_client).and_return(double)

      # 最初の2回は失敗、3回目は成功
      call_count = 0
      allow_any_instance_of(Aws::BedrockRuntime::Client).to receive(:invoke_model) do
        call_count += 1
        if call_count < 3
          raise Aws::BedrockRuntime::Errors::ServiceError.new(nil, 'Service error')
        else
          double(body: double(read: { content: [{ text: 'Success' }], usage: { input_tokens: 10, output_tokens: 20 } }.to_json))
        end
      end

      result = client.invoke(model_id: 'test-model', prompt: 'test')
      expect(result[:content]).to eq('Success')
      expect(call_count).to eq(3)
    end

    it 'raises BedrockApiError after MAX_RETRIES' do
      client = described_class.new
      allow_any_instance_of(Aws::BedrockRuntime::Client).to receive(:invoke_model).and_raise(
        Aws::BedrockRuntime::Errors::ServiceError.new(nil, 'Service error')
      )

      expect {
        client.invoke(model_id: 'test-model', prompt: 'test')
      }.to raise_error(Ai::BedrockApiError)
    end
  end
end
```

### Property 4: CSVエクスポートの完全性
**Validates: Requirements 2.8**

```ruby
# spec/controllers/admin/ai_usage_controller_spec.rb
RSpec.describe Admin::AiUsageController, type: :controller do
  describe 'GET #export' do
    it 'exports all AI generations within date range as CSV' do
      sign_in create(:admin_user)

      # テストデータ作成
      create(:ai_generation, feature_type: 'title', created_at: Date.today)
      create(:ai_generation, feature_type: 'summary', created_at: Date.today)

      get :export, params: { period: 'today', format: :csv }

      expect(response.content_type).to eq('text/csv')
      csv_data = CSV.parse(response.body, headers: true)
      expect(csv_data.length).to eq(2)
      expect(csv_data.headers).to include('ID', '機能', 'モデル', 'コスト(USD)')
    end
  end
end
```

---

## 📝 実装チェックリスト

### サービスクラス
- [ ] AI::StructureSuggesterのプロンプト改善
- [ ] AI::UsageStatisticsServiceの実装
- [ ] AI::BedrockClientのリトライ機能追加
- [ ] 各Suggester/Generatorのプロンプト改善

### コントローラー
- [ ] Admin::AiController#suggest_structureの実装
- [ ] Admin::AiUsageControllerの実装
- [ ] ルーティング追加

### ビュー
- [ ] 記事編集画面に構成提案セクション追加
- [ ] AI使用統計ページの実装
- [ ] Chart.jsグラフの実装

### フロントエンド
- [ ] ai_assistant_controller.jsの拡張
- [ ] Chart.jsのインストール・設定

### テスト
- [ ] StructureSuggesterのテスト
- [ ] UsageStatisticsServiceのテスト
- [ ] BedrockClientのリトライテスト
- [ ] AiUsageControllerのテスト

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**ステータス**: レビュー待ち
