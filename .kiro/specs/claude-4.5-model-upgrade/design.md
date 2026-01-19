# Claude 4.5 モデルアップグレード - 設計書

## 1. 設計概要

### 1.1 アプローチ
最小限の変更で確実にClaude 4.5へ移行する。既存のアーキテクチャを維持し、設定値のみを更新する。

### 1.2 設計原則
1. **後方互換性**: 既存データとの互換性を最優先
2. **最小変更**: ModelSelectorのみを変更
3. **段階的移行**: 必要に応じてモデルごとに切り替え可能
4. **明確な区別**: 新旧モデルを統計上で明確に区別

## 2. モデルID設計

### 2.1 新モデルID
AWS Bedrock cross-region inference profileを使用:

```ruby
# Claude 4.5 Sonnet (2025-01-14リリース)
"us.anthropic.claude-sonnet-4-20250514-v1:0"

# Claude 4.5 Haiku (利用可能な場合)
"us.anthropic.claude-haiku-4-5-v1:0"  # 仮のID、実際のIDは要確認
```

### 2.2 フォールバック戦略
Claude 4.5 Haikuが利用不可の場合:
- Option A: Claude 4.5 Sonnetを使用（品質優先）
- Option B: Claude 3 Haikuを継続使用（コスト優先）

**推奨**: Option A（品質とパフォーマンスの向上を優先）

### 2.3 モデルマッピング更新

```ruby
MODELS = {
  summary: "us.anthropic.claude-sonnet-4-20250514-v1:0",      # 要約生成
  title: "us.anthropic.claude-sonnet-4-20250514-v1:0",        # タイトル提案
  tags: "us.anthropic.claude-sonnet-4-20250514-v1:0",         # タグ抽出（Sonnetに変更）
  slug: "us.anthropic.claude-sonnet-4-20250514-v1:0",         # スラッグ生成（Sonnetに変更）
  seo_meta: "us.anthropic.claude-sonnet-4-20250514-v1:0",     # SEOメタ生成
  structure: "us.anthropic.claude-sonnet-4-20250514-v1:0"     # 構造提案
}.freeze
```

**変更理由**:
- Claude 4.5 Haikuの利用可能性が不明
- 全機能でClaude 4.5 Sonnetを使用することで一貫性を確保
- Claude 4.5 Sonnetは高速化されており、Haikuとの速度差が縮小

## 3. コスト設計

### 3.1 料金情報
Claude 4.5 Sonnetの料金（2025年1月時点、要確認）:

```ruby
MODEL_COSTS = {
  # Claude 4.5 Sonnet
  "us.anthropic.claude-sonnet-4-20250514-v1:0" => {
    input: 3.0,   # $3.00 per 1M tokens
    output: 15.0  # $15.00 per 1M tokens
  },
  
  # 後方互換性のため旧モデルも保持
  "us.anthropic.claude-3-5-sonnet-20241022-v2:0" => {
    input: 3.0,
    output: 15.0
  },
  "us.anthropic.claude-3-haiku-20240307-v1:0" => {
    input: 0.25,
    output: 1.25
  },
  
  # レガシーID（後方互換性）
  "anthropic.claude-3-5-sonnet-20241022-v2:0" => {
    input: 3.0,
    output: 15.0
  },
  "anthropic.claude-3-haiku-20240307-v1:0" => {
    input: 0.25,
    output: 1.25
  }
}.freeze
```

**注意**: Claude 4.5の実際の料金は公式ドキュメントで確認が必要

### 3.2 コスト影響分析
現在の使用パターンを仮定:
- tags/slugをHaikuからSonnetに変更: コスト増加（約12倍）
- ただし、これらは短いテキスト処理のため、実際の影響は限定的
- Claude 4.5の高速化により、全体的な効率は向上

## 4. 表示名設計

### 4.1 display_nameメソッド更新

```ruby
def self.display_name(model_id)
  case model_id
  # Claude 4.5
  when /us\.anthropic\.claude-sonnet-4-20250514/
    "Claude Sonnet 4 (2025-05-14)"
  when /us\.anthropic\.claude-haiku-4-5/
    "Claude Haiku 4.5"
  when /claude-sonnet-4-20250514/
    "Claude Sonnet 4 (2025-05-14)"
    
  # Claude 3.5 (後方互換性)
  when /us\.anthropic\.claude-3-5-sonnet/
    "Claude 3.5 Sonnet"
  when /us\.anthropic\.claude-3-haiku/
    "Claude 3 Haiku"
  when /claude-3-5-sonnet/
    "Claude 3.5 Sonnet"
  when /claude-3-haiku/
    "Claude 3 Haiku"
    
  # その他
  when /claude-sonnet-4-5/
    "Claude Sonnet 4.5"
  when /claude-haiku-4-5/
    "Claude Haiku 4.5"
  else
    model_id
  end
end
```

### 4.2 表示名の方針
- バージョン番号を明示（統計での区別を容易に）
- リリース日を含める（Claude 4の場合）
- 新旧モデルが混在しても識別可能

## 5. データベース設計

### 5.1 既存スキーマ
変更なし。`ai_usage_stats.ai_model`カラムに新しいモデルIDが保存される。

```ruby
# ai_usage_stats
- date: date
- ai_model: string  # 新モデルID: "us.anthropic.claude-sonnet-4-20250514-v1:0"
- total_requests: integer
- total_tokens: integer
- total_cost: decimal
- breakdown: jsonb
```

### 5.2 データ移行
不要。新旧モデルは別レコードとして管理される。

## 6. 統計・レポート設計

### 6.1 UsageTrackerの動作
変更なし。ModelSelector.display_nameを使用して表示名を取得。

```ruby
def model_breakdown(stats)
  stats.group(:ai_model).pluck(...).map do |model, requests, tokens, cost|
    {
      model: model,
      display_name: ModelSelector.display_name(model),  # 新モデルに対応
      requests: requests.to_i,
      tokens: tokens.to_i,
      cost: cost.to_f.round(2)
    }
  end
end
```

### 6.2 レポート表示
- 新旧モデルは別行として表示される
- 月次レポートで新旧の使用状況を比較可能
- コスト推移を追跡可能

## 7. エラーハンドリング

### 7.1 モデル利用不可エラー
```ruby
# BedrockClientでのエラーハンドリング（既存）
rescue Aws::Bedrock::Errors::ValidationException => e
  Rails.logger.error("Model not available: #{e.message}")
  raise Ai::ModelNotAvailableError, "Claude 4.5 is not available in this region"
end
```

### 7.2 フォールバック
現時点ではフォールバックを実装しない。エラー時は明示的に失敗させる。

## 8. テスト設計

### 8.1 単体テスト
```ruby
# spec/services/ai/model_selector_spec.rb
describe Ai::ModelSelector do
  describe '.select' do
    it 'returns Claude 4.5 Sonnet for summary' do
      expect(described_class.select(:summary))
        .to eq('us.anthropic.claude-sonnet-4-20250514-v1:0')
    end
  end
  
  describe '.display_name' do
    it 'returns correct name for Claude 4.5' do
      expect(described_class.display_name('us.anthropic.claude-sonnet-4-20250514-v1:0'))
        .to eq('Claude Sonnet 4 (2025-05-14)')
    end
    
    it 'returns correct name for Claude 3.5 (backward compatibility)' do
      expect(described_class.display_name('us.anthropic.claude-3-5-sonnet-20241022-v2:0'))
        .to eq('Claude 3.5 Sonnet')
    end
  end
  
  describe '.calculate_cost' do
    it 'calculates cost correctly for Claude 4.5' do
      cost = described_class.calculate_cost(
        'us.anthropic.claude-sonnet-4-20250514-v1:0',
        1000,  # input tokens
        500    # output tokens
      )
      expect(cost).to eq(0.0105)  # (1000*3 + 500*15) / 1_000_000
    end
  end
end
```

### 8.2 統合テスト
```ruby
# spec/services/ai/usage_tracker_spec.rb
describe Ai::UsageTracker do
  describe '.track' do
    it 'tracks usage with Claude 4.5 model' do
      described_class.track(
        model_id: 'us.anthropic.claude-sonnet-4-20250514-v1:0',
        generation_type: :summary,
        tokens: 1000,
        cost: 0.01
      )
      
      stat = AiUsageStat.for_today('us.anthropic.claude-sonnet-4-20250514-v1:0')
      expect(stat.total_requests).to eq(1)
      expect(stat.total_tokens).to eq(1000)
    end
  end
  
  describe '.summary' do
    it 'includes both old and new models in breakdown' do
      # Create stats for both models
      AiUsageStat.create!(
        date: Date.current,
        ai_model: 'us.anthropic.claude-3-5-sonnet-20241022-v2:0',
        total_requests: 10,
        total_tokens: 5000,
        total_cost: 0.05
      )
      AiUsageStat.create!(
        date: Date.current,
        ai_model: 'us.anthropic.claude-sonnet-4-20250514-v1:0',
        total_requests: 5,
        total_tokens: 3000,
        total_cost: 0.03
      )
      
      summary = described_class.summary(
        start_date: Date.current,
        end_date: Date.current
      )
      
      expect(summary[:by_model].size).to eq(2)
      expect(summary[:by_model].map { |m| m[:display_name] })
        .to contain_exactly('Claude 3.5 Sonnet', 'Claude Sonnet 4 (2025-05-14)')
    end
  end
end
```

### 8.3 手動テスト
1. 各generation_typeでAI生成を実行
2. 管理画面で使用統計を確認
3. モデル名が正しく表示されることを確認
4. コストが正確に計算されることを確認

## 9. デプロイ計画

### 9.1 デプロイ手順
1. テスト環境でモデルIDを更新
2. 各機能をテスト実行
3. 統計画面で正しく記録されることを確認
4. 本番環境にデプロイ
5. 本番環境で動作確認

### 9.2 ロールバック手順
1. `model_selector.rb`のMODELSを旧IDに戻す
2. 再デプロイ
3. 統計データは保持される（新旧別レコード）

### 9.3 モニタリング
- Railsログでモデル使用状況を確認
- 管理画面で統計を確認
- エラーログを監視

## 10. 正確性プロパティ

### 10.1 モデル選択の正確性
**プロパティ**: 全てのgeneration_typeに対して、selectメソッドは有効なClaude 4.5モデルIDを返す

**検証方法**:
```ruby
property "select returns valid Claude 4.5 model ID" do
  generation_types = [:summary, :title, :tags, :slug, :seo_meta, :structure]
  
  generation_types.all? do |type|
    model_id = Ai::ModelSelector.select(type)
    model_id.start_with?('us.anthropic.claude-sonnet-4-')
  end
end
```

### 10.2 コスト計算の正確性
**プロパティ**: 任意のトークン数に対して、コスト計算は非負の値を返し、トークン数に比例する

**検証方法**:
```ruby
property "calculate_cost returns non-negative proportional value" do
  model_id = 'us.anthropic.claude-sonnet-4-20250514-v1:0'
  input_tokens = rand(1..100000)
  output_tokens = rand(1..100000)
  
  cost = Ai::ModelSelector.calculate_cost(model_id, input_tokens, output_tokens)
  
  cost >= 0 &&
    cost == ((input_tokens * 3.0 + output_tokens * 15.0) / 1_000_000.0).round(6)
end
```

### 10.3 表示名の一貫性
**プロパティ**: 全ての有効なモデルIDに対して、display_nameは空でない文字列を返す

**検証方法**:
```ruby
property "display_name returns non-empty string for all model IDs" do
  model_ids = [
    'us.anthropic.claude-sonnet-4-20250514-v1:0',
    'us.anthropic.claude-3-5-sonnet-20241022-v2:0',
    'us.anthropic.claude-3-haiku-20240307-v1:0'
  ]
  
  model_ids.all? do |model_id|
    name = Ai::ModelSelector.display_name(model_id)
    name.is_a?(String) && !name.empty?
  end
end
```

### 10.4 統計記録の整合性
**プロパティ**: trackメソッドを呼び出した後、対応するAiUsageStatレコードが存在し、値が増加する

**検証方法**:
```ruby
property "track increases usage stats" do
  model_id = 'us.anthropic.claude-sonnet-4-20250514-v1:0'
  
  before_stat = AiUsageStat.for_today(model_id)
  before_requests = before_stat.total_requests || 0
  
  Ai::UsageTracker.track(
    model_id: model_id,
    generation_type: :summary,
    tokens: 100,
    cost: 0.001
  )
  
  after_stat = AiUsageStat.for_today(model_id)
  after_stat.total_requests == before_requests + 1
end
```

## 11. 実装チェックリスト

- [ ] MODELSハッシュを更新
- [ ] MODEL_COSTSハッシュを更新
- [ ] display_nameメソッドを更新
- [ ] 単体テストを追加/更新
- [ ] 統合テストを追加/更新
- [ ] テスト環境で動作確認
- [ ] 本番環境にデプロイ
- [ ] 本番環境で動作確認
- [ ] 統計画面で新モデルの使用を確認

## 12. 注意事項

### 12.1 料金確認
実装前に必ずAWS Bedrockの公式ドキュメントでClaude 4.5の料金を確認すること。

### 12.2 モデルID確認
AWS Bedrockコンソールまたはドキュメントで正確なモデルIDを確認すること。

### 12.3 リージョン制約
使用しているAWSリージョンでClaude 4.5が利用可能か確認すること。

### 12.4 段階的移行
必要に応じて、一部の機能のみを先行して移行することも可能。
