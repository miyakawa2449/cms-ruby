# Phase 5.5: AI機能改善 - 実装ガイド（Claude Code向け）

**Phase**: 5.5  
**担当**: Claude Code（実装担当）  
**実施期間**: 2026-01-19 〜 2026-01-20（2日間）  
**作成日**: 2026-01-18

---

## 🎯 実装の目的

Phase 5.2で実装したAI機能（Amazon Bedrock連携）を改善・拡張します：
1. **記事構成提案機能の有効化**: StructureSuggesterをUI統合
2. **AI使用量ダッシュボード**: トークン使用量・コストの可視化
3. **プロンプト品質向上**: 各サービスのプロンプト改善

---

## 📋 実装タスク（11タスク）

### Day 1（2026-01-19）: バックエンド実装

#### Task 1: Setup and Dependencies ⚙️
```bash
# Chart.jsのインストール
npm install chart.js@^4.4.0

# ルーティング追加
# config/routes.rb に以下を追加
namespace :admin do
  namespace :ai do
    post :suggest_structure
  end
  resources :ai_usage, only: [:index] do
    collection do
      get :export
    end
  end
end
```

**チェックリスト**:
- [ ] package.jsonにchart.js追加
- [ ] ルーティング追加
- [ ] AiGenerationモデルにstructure feature_type追加確認

---

#### Task 2: AI::StructureSuggester - プロンプト改善 📝

**ファイル**: `app/services/ai/structure_suggester.rb`

**実装内容**:

1. プロンプトを改善（より具体的な構成提案）
2. 日本語出力の精度向上
3. エラーハンドリング強化
4. ユニットテストの実装

**改善ポイント**:
- システムプロンプトに「日本語で回答してください」を明記
- 出力形式の具体例を提示（Markdown形式）
- H2/H3レベルの見出し構成を生成

**参考**: 既存の`app/services/ai/title_suggester.rb`を参考にする

---

#### Task 3: AI::UsageStatisticsService - 統計サービス実装 📊

**ファイル**: `app/services/ai/usage_statistics_service.rb`（新規作成）

**実装メソッド**:
```ruby
class Ai::UsageStatisticsService
  # 日別使用量
  def self.daily_usage(start_date, end_date)
    # AiUsageStatから日別データを取得
  end

  # 月別使用量
  def self.monthly_usage(year, month)
    # 指定月のデータを集計
  end

  # 機能別使用量
  def self.usage_by_feature(start_date, end_date)
    # feature_type別に集計
  end

  # 総コスト計算
  def self.total_cost(start_date, end_date)
    # total_cost_usdを合計
  end

  # 使用量ランキング
  def self.top_features(limit = 5)
    # request_count順にソート
  end

  # CSVエクスポート用データ
  def self.export_data(start_date, end_date)
    # CSV形式のデータを生成
  end
end
```

**チェックリスト**:
- [ ] 各メソッドの実装
- [ ] AiUsageStatモデルとの連携
- [ ] ユニットテストの実装

---

#### Task 4: AI::BedrockClient - リトライ機能追加 🔄

**ファイル**: `app/services/ai/bedrock_client.rb`

**実装内容**:
1. リトライロジック（最大3回、指数バックオフ）
2. タイムアウト設定（30秒）
3. カスタム例外クラス追加
4. エラーログの詳細化

**実装例**:
```ruby
class Ai::BedrockClient
  MAX_RETRIES = 3
  TIMEOUT = 30

  def invoke(model_id:, prompt:)
    retries = 0
    begin
      Timeout.timeout(TIMEOUT) do
        # API呼び出し
      end
    rescue Timeout::Error => e
      raise Ai::BedrockTimeoutError, "API timeout after #{TIMEOUT}s"
    rescue StandardError => e
      retries += 1
      if retries < MAX_RETRIES
        sleep(2 ** retries) # 指数バックオフ
        retry
      else
        raise Ai::BedrockApiError, "API error: #{e.message}"
      end
    end
  end
end

# カスタム例外クラス
class Ai::BedrockApiError < StandardError; end
class Ai::BedrockTimeoutError < StandardError; end
```

---

#### Task 5: Admin::AiController - 構成提案エンドポイント追加 🎯

**ファイル**: `app/controllers/admin/ai_controller.rb`

**実装内容**:
```ruby
def suggest_structure
  topic = params[:topic]
  
  if topic.blank?
    render json: { error: 'トピックを入力してください' }, status: :unprocessable_entity
    return
  end

  begin
    suggester = Ai::StructureSuggester.new(topic: topic)
    result = suggester.suggest
    
    render json: { structure: result[:structure] }
  rescue Ai::BedrockApiError, Ai::BedrockTimeoutError => e
    render json: { error: "AI機能でエラーが発生しました: #{e.message}" }, status: :service_unavailable
  end
end
```

**チェックリスト**:
- [ ] suggest_structureアクション実装
- [ ] パラメータバリデーション
- [ ] エラーハンドリング
- [ ] 統合テストの実装

---

### Day 2（2026-01-20）: フロントエンド実装

#### Task 6: Admin::AiUsageController - 統計ページ実装 📈

**ファイル**: `app/controllers/admin/ai_usage_controller.rb`（新規作成）

**実装内容**:
```ruby
class Admin::AiUsageController < Admin::BaseController
  def index
    @start_date = params[:start_date] || 30.days.ago.to_date
    @end_date = params[:end_date] || Date.today
    
    @daily_usage = Ai::UsageStatisticsService.daily_usage(@start_date, @end_date)
    @usage_by_feature = Ai::UsageStatisticsService.usage_by_feature(@start_date, @end_date)
    @total_cost = Ai::UsageStatisticsService.total_cost(@start_date, @end_date)
    @top_features = Ai::UsageStatisticsService.top_features(5)
  end

  def export
    @start_date = params[:start_date] || 30.days.ago.to_date
    @end_date = params[:end_date] || Date.today
    
    data = Ai::UsageStatisticsService.export_data(@start_date, @end_date)
    
    send_data data, filename: "ai_usage_#{@start_date}_#{@end_date}.csv", type: 'text/csv'
  end
end
```

---

#### Task 7: 記事編集画面 - 構成提案UI追加 ✏️

**ファイル**: `app/views/admin/articles/_form.html.erb`

**追加箇所**: タイトル提案セクションの下に追加

**実装内容**:
```erb
<!-- 構成提案セクション -->
<div class="mb-6 p-4 bg-blue-50 rounded-lg" data-controller="ai-assistant">
  <h3 class="text-lg font-semibold mb-3">📝 記事構成提案</h3>
  
  <div class="mb-3">
    <label class="block text-sm font-medium mb-2">トピック</label>
    <textarea 
      data-ai-assistant-target="structureTopic"
      class="w-full px-3 py-2 border rounded-lg"
      rows="2"
      placeholder="記事のテーマを入力してください（例: Railsのパフォーマンス最適化）"
    ></textarea>
  </div>
  
  <button 
    type="button"
    data-action="click->ai-assistant#suggestStructure"
    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
  >
    構成を提案
  </button>
  
  <div data-ai-assistant-target="structureResult" class="mt-4 hidden">
    <div class="bg-white p-4 rounded-lg border">
      <div class="flex justify-between items-center mb-2">
        <h4 class="font-semibold">提案された構成</h4>
        <button 
          type="button"
          data-action="click->ai-assistant#insertStructure"
          class="px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700 text-sm"
        >
          本文に挿入
        </button>
      </div>
      <pre data-ai-assistant-target="structureContent" class="whitespace-pre-wrap text-sm"></pre>
    </div>
  </div>
  
  <div data-ai-assistant-target="structureLoading" class="mt-4 hidden">
    <div class="flex items-center text-blue-600">
      <svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      構成を生成中...
    </div>
  </div>
</div>
```

---

#### Task 8: AI使用統計ページ - ビュー実装 📊

**ファイル**: `app/views/admin/ai_usage/index.html.erb`（新規作成）

**実装内容**:
1. ページタイトル「AI使用統計」
2. 期間フィルター（今日、今週、今月、カスタム）
3. サマリーカード（総トークン数、推定コスト、総リクエスト数）
4. 日別使用量グラフ（Chart.js）
5. 機能別使用量グラフ（円グラフ）
6. 使用履歴テーブル
7. CSVエクスポートボタン

**Chart.js実装例**:
```javascript
// 日別使用量グラフ
const ctx = document.getElementById('dailyUsageChart');
new Chart(ctx, {
  type: 'line',
  data: {
    labels: <%= @daily_usage.map(&:date).to_json.html_safe %>,
    datasets: [{
      label: 'トークン使用量',
      data: <%= @daily_usage.map { |d| d.total_input_tokens + d.total_output_tokens }.to_json.html_safe %>,
      borderColor: 'rgb(59, 130, 246)',
      tension: 0.1
    }]
  }
});
```

---

#### Task 9: Stimulusコントローラー - 構成提案機能追加 🎮

**ファイル**: `app/javascript/controllers/ai_assistant_controller.js`

**追加メソッド**:
```javascript
// 構成提案
async suggestStructure(event) {
  event.preventDefault();
  
  const topic = this.structureTopicTarget.value.trim();
  if (!topic) {
    alert('トピックを入力してください');
    return;
  }
  
  this.showStructureLoading();
  
  try {
    const response = await fetch('/admin/ai/suggest_structure', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({ topic })
    });
    
    const data = await response.json();
    
    if (response.ok) {
      this.displayStructure(data.structure);
    } else {
      this.showStructureError(data.error);
    }
  } catch (error) {
    this.showStructureError('通信エラーが発生しました');
  } finally {
    this.hideStructureLoading();
  }
}

// 構成表示
displayStructure(structure) {
  this.structureContentTarget.textContent = structure;
  this.structureResultTarget.classList.remove('hidden');
}

// 本文に挿入
insertStructure(event) {
  event.preventDefault();
  
  const structure = this.structureContentTarget.textContent;
  const contentField = document.querySelector('#article_content');
  
  if (contentField) {
    contentField.value += '\n\n' + structure;
    alert('構成を本文に挿入しました');
  }
}

// ローディング表示
showStructureLoading() {
  this.structureLoadingTarget.classList.remove('hidden');
  this.structureResultTarget.classList.add('hidden');
}

hideStructureLoading() {
  this.structureLoadingTarget.classList.add('hidden');
}

// エラー表示
showStructureError(message) {
  alert(message);
}
```

**Stimulusターゲット追加**:
```javascript
static targets = [
  // 既存のターゲット
  "titleContent", "titleResult", "titleLoading",
  // 新規追加
  "structureTopic", "structureContent", "structureResult", "structureLoading"
]
```

---

#### Task 10: プロンプト品質向上 - 各サービスの改善 ✨

**対象ファイル**:
1. `app/services/ai/title_suggester.rb`
2. `app/services/ai/summary_generator.rb`
3. `app/services/ai/tag_suggester.rb`
4. `app/services/ai/slug_generator.rb`
5. `app/services/ai/seo_meta_generator.rb`

**改善方針**:
- システムプロンプトに「日本語で回答してください」を明記
- 出力形式の具体例を提示
- 文体の統一（です・ます調）
- コンテキストの充実（記事内容、ターゲット読者層）
- 制約条件の明示（文字数、形式）

**実装例（TitleSuggester）**:
```ruby
def build_prompt
  <<~PROMPT
    あなたはプロのコピーライターです。以下の記事内容から、魅力的なタイトルを2種類提案してください。

    【記事内容】
    #{@article.content}

    【要件】
    1. わかりやすいタイトル: 内容が一目で分かる、シンプルで明確なタイトル（30文字以内）
    2. SNS映えタイトル: クリックしたくなる、キャッチーなタイトル（30文字以内）

    【出力形式】
    わかりやすいタイトル
    SNS映えタイトル

    【注意事項】
    - 日本語で回答してください
    - 各タイトルは1行で出力してください
    - 記号や絵文字は使用しないでください
  PROMPT
end
```

---

#### Task 11: Final Integration and Testing 🧪

**実装内容**:
1. 全機能の統合テスト
2. エラーケースのテスト
3. パフォーマンステスト
4. ドキュメント更新

**テストチェックリスト**:
- [ ] 記事編集画面で構成提案が動作する
- [ ] AI使用統計ページが表示される
- [ ] グラフが正しく描画される
- [ ] CSVエクスポートが動作する
- [ ] エラーハンドリングが適切に動作する
- [ ] リトライ機能が動作する

**統合テスト実行**:
```bash
# RSpecテスト実行
bundle exec rspec spec/services/ai/
bundle exec rspec spec/controllers/admin/ai_controller_spec.rb
bundle exec rspec spec/controllers/admin/ai_usage_controller_spec.rb

# 手動テスト
# 1. 記事編集画面で構成提案を試す
# 2. AI使用統計ページを確認
# 3. CSVエクスポートを試す
```

---

## 📁 ファイル構成

### 新規作成ファイル
```
app/
├── services/
│   └── ai/
│       └── usage_statistics_service.rb
├── controllers/
│   └── admin/
│       └── ai_usage_controller.rb
└── views/
    └── admin/
        └── ai_usage/
            └── index.html.erb

spec/
├── services/
│   └── ai/
│       ├── structure_suggester_spec.rb
│       ├── usage_statistics_service_spec.rb
│       └── bedrock_client_spec.rb
└── controllers/
    └── admin/
        └── ai_usage_controller_spec.rb
```

### 修正ファイル
```
app/
├── services/
│   └── ai/
│       ├── structure_suggester.rb（プロンプト改善）
│       ├── bedrock_client.rb（リトライ機能追加）
│       ├── title_suggester.rb（プロンプト改善）
│       ├── summary_generator.rb（プロンプト改善）
│       ├── tag_suggester.rb（プロンプト改善）
│       ├── slug_generator.rb（プロンプト改善）
│       └── seo_meta_generator.rb（プロンプト改善）
├── controllers/
│   └── admin/
│       └── ai_controller.rb（suggest_structureアクション追加）
├── views/
│   └── admin/
│       └── articles/
│           └── _form.html.erb（構成提案UI追加）
└── javascript/
    └── controllers/
        └── ai_assistant_controller.js（構成提案機能追加）

config/
└── routes.rb（ルーティング追加）

package.json（Chart.js追加）
```

---

## 🔍 重要な注意事項

### 1. エラーハンドリング
- AI APIエラー時もアプリケーションは正常動作すること
- ユーザーフレンドリーなエラーメッセージを表示
- エラーログを詳細に記録

### 2. パフォーマンス
- AI使用量ダッシュボードのグラフ描画は3秒以内
- 統計データのクエリは1秒以内
- 記事構成提案は10秒以内に完了

### 3. セキュリティ
- AI使用統計ページは管理者のみアクセス可能
- CSVエクスポートは認証必須
- APIエンドポイントはCSRF保護

### 4. テスト
- 各サービスクラスのユニットテスト必須
- コントローラーの統合テスト必須
- エラーケースのテストも実装

---

## 📚 参考ドキュメント

- [要件定義](./requirements.md)
- [設計書](./design.md)
- [タスクリスト](./tasks.md)
- [機能仕様書](../../docs/specifications/features/5.5_ai_improvements.md)

---

## ✅ 完了条件

- [ ] 全11タスクが完了
- [ ] 全テストがパス
- [ ] 記事編集画面で構成提案が動作
- [ ] AI使用統計ページが表示
- [ ] CSVエクスポートが動作
- [ ] エラーハンドリングが適切に動作
- [ ] コードレビュー完了（Kiro）

---

**作成日**: 2026-01-18  
**作成者**: Kiro  
**対象**: Claude Code（実装担当）
