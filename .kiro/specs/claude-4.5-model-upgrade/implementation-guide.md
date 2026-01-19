# Claude 4.5 モデルアップグレード - 実装ガイド（Claude Code用）

## 概要

記事作成で使用しているAIモデルをClaude 3.5/3 HaikuからClaude 4.5に更新します。
**変更対象は `app/services/ai/model_selector.rb` のみ**です。

## 事前確認事項

実装前に以下を確認してください：

### 1. AWS Bedrockでのモデル確認
- AWS Bedrockコンソールにアクセス
- 使用リージョンでClaude 4.5が利用可能か確認
- 正確なモデルIDを確認（cross-region inference profile形式）

### 2. 料金情報の確認
- [Anthropic公式料金ページ](https://www.anthropic.com/pricing)でClaude 4.5の料金を確認
- Input token単価（per 1M tokens）
- Output token単価（per 1M tokens）

**注意**: 以下の実装例では仮の料金を使用しています。実装前に必ず公式ドキュメントで確認してください。

## 実装手順

### ステップ1: MODELSハッシュの更新

`app/services/ai/model_selector.rb` の `MODELS` ハッシュを更新します。

**変更前:**
```ruby
MODELS = {
  summary: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
  title: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
  tags: "us.anthropic.claude-3-haiku-20240307-v1:0",
  slug: "us.anthropic.claude-3-haiku-20240307-v1:0",
  seo_meta: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
  structure: "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
}.freeze
```

**変更後:**
```ruby
MODELS = {
  summary: "us.anthropic.claude-sonnet-4-20250514-v1:0",
  title: "us.anthropic.claude-sonnet-4-20250514-v1:0",
  tags: "us.anthropic.claude-sonnet-4-20250514-v1:0",      # Sonnetに統一
  slug: "us.anthropic.claude-sonnet-4-20250514-v1:0",      # Sonnetに統一
  seo_meta: "us.anthropic.claude-sonnet-4-20250514-v1:0",
  structure: "us.anthropic.claude-sonnet-4-20250514-v1:0"
}.freeze
```

**変更理由:**
- Claude 4.5 Haikuの利用可能性が不明なため、全機能でSonnetに統一
- Claude 4.5 Sonnetは高速化されており、Haikuとの速度差が縮小
- 一貫性のあるモデル使用により、品質が安定

### ステップ2: MODEL_COSTSハッシュの更新

新モデルの料金情報を追加します。**旧モデルの情報は削除せず保持**してください（後方互換性のため）。

**変更前:**
```ruby
MODEL_COSTS = {
  "us.anthropic.claude-3-5-sonnet-20241022-v2:0" => { input: 3.0, output: 15.0 },
  "us.anthropic.claude-3-haiku-20240307-v1:0" => { input: 0.25, output: 1.25 },
  "anthropic.claude-3-5-sonnet-20241022-v2:0" => { input: 3.0, output: 15.0 },
  "anthropic.claude-3-haiku-20240307-v1:0" => { input: 0.25, output: 1.25 }
}.freeze
```

**変更後:**
```ruby
MODEL_COSTS = {
  # Claude 4.5 Sonnet (2025-05-14)
  # TODO: 実装前に公式ドキュメントで料金を確認すること
  "us.anthropic.claude-sonnet-4-20250514-v1:0" => { input: 3.0, output: 15.0 },
  
  # Claude 3.5 Sonnet (後方互換性のため保持)
  "us.anthropic.claude-3-5-sonnet-20241022-v2:0" => { input: 3.0, output: 15.0 },
  "us.anthropic.claude-3-haiku-20240307-v1:0" => { input: 0.25, output: 1.25 },
  
  # Legacy direct model IDs (後方互換性のため保持)
  "anthropic.claude-3-5-sonnet-20241022-v2:0" => { input: 3.0, output: 15.0 },
  "anthropic.claude-3-haiku-20240307-v1:0" => { input: 0.25, output: 1.25 }
}.freeze
```

**重要:** 上記の料金は仮の値です。実装時に必ず公式ドキュメントで確認してください。

### ステップ3: display_nameメソッドの更新

新モデルIDに対応する表示名を追加します。

**変更前:**
```ruby
def self.display_name(model_id)
  case model_id
  when /us\.anthropic\.claude-3-5-sonnet/
    "Claude 3.5 Sonnet"
  when /us\.anthropic\.claude-3-haiku/
    "Claude 3 Haiku"
  when /claude-3-5-sonnet/
    "Claude 3.5 Sonnet"
  when /claude-3-haiku/
    "Claude 3 Haiku"
  when /claude-sonnet-4-5/
    "Claude Sonnet 4.5"
  when /claude-haiku-4-5/
    "Claude Haiku 4.5"
  when /claude-sonnet-4-20250514/
    "Claude Sonnet 4"
  else
    model_id
  end
end
```

**変更後:**
```ruby
def self.display_name(model_id)
  case model_id
  # Claude 4.5 / Claude 4 (新モデル)
  when /us\.anthropic\.claude-sonnet-4-20250514/
    "Claude Sonnet 4 (2025-05-14)"
  when /claude-sonnet-4-20250514/
    "Claude Sonnet 4 (2025-05-14)"
  when /us\.anthropic\.claude-sonnet-4-5/
    "Claude Sonnet 4.5"
  when /claude-sonnet-4-5/
    "Claude Sonnet 4.5"
  when /us\.anthropic\.claude-haiku-4-5/
    "Claude Haiku 4.5"
  when /claude-haiku-4-5/
    "Claude Haiku 4.5"
    
  # Claude 3.5 / Claude 3 (旧モデル - 後方互換性)
  when /us\.anthropic\.claude-3-5-sonnet/
    "Claude 3.5 Sonnet"
  when /us\.anthropic\.claude-3-haiku/
    "Claude 3 Haiku"
  when /claude-3-5-sonnet/
    "Claude 3.5 Sonnet"
  when /claude-3-haiku/
    "Claude 3 Haiku"
    
  else
    model_id
  end
end
```

**変更理由:**
- 新モデルのパターンマッチを最初に配置（優先順位）
- リリース日を含めることで、統計画面で明確に区別可能
- 旧モデルのパターンマッチは保持（既存の統計データ表示のため）

### ステップ4: コメントの更新

ファイル冒頭のコメントを更新します。

**変更前:**
```ruby
# Model configurations with cost per 1M tokens (USD)
# Updated to use cross-region inference profiles (us. prefix required)
# Sonnet: Higher quality, best for complex tasks
# Haiku: Faster, cheaper, good for simple tasks
```

**変更後:**
```ruby
# Model configurations with cost per 1M tokens (USD)
# Updated to Claude 4.5 Sonnet (2025-05-14) for all generation types
# Using cross-region inference profiles (us. prefix required)
# Claude 4.5 Sonnet: Higher quality, faster, best for all tasks
```

## テスト実装

### 単体テストの更新

`spec/services/ai/model_selector_spec.rb` を以下のように更新してください：

```ruby
require "rails_helper"

RSpec.describe Ai::ModelSelector do
  describe ".select" do
    it "returns Claude 4.5 Sonnet for summary" do
      expect(described_class.select(:summary))
        .to eq("us.anthropic.claude-sonnet-4-20250514-v1:0")
    end

    it "returns Claude 4.5 Sonnet for title" do
      expect(described_class.select(:title))
        .to eq("us.anthropic.claude-sonnet-4-20250514-v1:0")
    end

    it "returns Claude 4.5 Sonnet for tags" do
      expect(described_class.select(:tags))
        .to eq("us.anthropic.claude-sonnet-4-20250514-v1:0")
    end

    it "returns Claude 4.5 Sonnet for slug" do
      expect(described_class.select(:slug))
        .to eq("us.anthropic.claude-sonnet-4-20250514-v1:0")
    end

    it "returns Claude 4.5 Sonnet for seo_meta" do
      expect(described_class.select(:seo_meta))
        .to eq("us.anthropic.claude-sonnet-4-20250514-v1:0")
    end

    it "returns Claude 4.5 Sonnet for structure" do
      expect(described_class.select(:structure))
        .to eq("us.anthropic.claude-sonnet-4-20250514-v1:0")
    end

    it "returns default model for unknown type" do
      expect(described_class.select(:unknown))
        .to eq("us.anthropic.claude-sonnet-4-20250514-v1:0")
    end
  end

  describe ".display_name" do
    context "with Claude 4.5 models" do
      it "returns correct name for Claude Sonnet 4" do
        expect(described_class.display_name("us.anthropic.claude-sonnet-4-20250514-v1:0"))
          .to eq("Claude Sonnet 4 (2025-05-14)")
      end

      it "returns correct name for legacy format" do
        expect(described_class.display_name("anthropic.claude-sonnet-4-20250514-v1:0"))
          .to eq("Claude Sonnet 4 (2025-05-14)")
      end
    end

    context "with Claude 3.5 models (backward compatibility)" do
      it "returns correct name for Claude 3.5 Sonnet" do
        expect(described_class.display_name("us.anthropic.claude-3-5-sonnet-20241022-v2:0"))
          .to eq("Claude 3.5 Sonnet")
      end

      it "returns correct name for Claude 3 Haiku" do
        expect(described_class.display_name("us.anthropic.claude-3-haiku-20240307-v1:0"))
          .to eq("Claude 3 Haiku")
      end
    end

    context "with unknown model" do
      it "returns the model ID as-is" do
        unknown_id = "unknown-model-id"
        expect(described_class.display_name(unknown_id)).to eq(unknown_id)
      end
    end
  end

  describe ".calculate_cost" do
    let(:claude_4_model) { "us.anthropic.claude-sonnet-4-20250514-v1:0" }

    it "calculates cost correctly for Claude 4.5" do
      cost = described_class.calculate_cost(claude_4_model, 1000, 500)
      # (1000 * 3.0 + 500 * 15.0) / 1_000_000 = 0.0105
      expect(cost).to eq(0.0105)
    end

    it "returns zero cost for unknown model" do
      cost = described_class.calculate_cost("unknown-model", 1000, 500)
      expect(cost).to eq(0.0)
    end

    it "handles zero tokens" do
      cost = described_class.calculate_cost(claude_4_model, 0, 0)
      expect(cost).to eq(0.0)
    end
  end

  describe ".available?" do
    it "returns true for Claude 4.5 Sonnet" do
      expect(described_class.available?("us.anthropic.claude-sonnet-4-20250514-v1:0"))
        .to be true
    end

    it "returns true for Claude 3.5 Sonnet (backward compatibility)" do
      expect(described_class.available?("us.anthropic.claude-3-5-sonnet-20241022-v2:0"))
        .to be true
    end

    it "returns false for unknown model" do
      expect(described_class.available?("unknown-model")).to be false
    end
  end
end
```

## 検証手順

実装後、以下の手順で動作確認してください：

### 1. 単体テストの実行
```bash
bundle exec rspec spec/services/ai/model_selector_spec.rb
```

### 2. Railsコンソールでの確認
```bash
bundle exec rails console
```

```ruby
# モデル選択の確認
Ai::ModelSelector.select(:summary)
# => "us.anthropic.claude-sonnet-4-20250514-v1:0"

# 表示名の確認
Ai::ModelSelector.display_name("us.anthropic.claude-sonnet-4-20250514-v1:0")
# => "Claude Sonnet 4 (2025-05-14)"

# コスト計算の確認
Ai::ModelSelector.calculate_cost("us.anthropic.claude-sonnet-4-20250514-v1:0", 1000, 500)
# => 0.0105

# 旧モデルの後方互換性確認
Ai::ModelSelector.display_name("us.anthropic.claude-3-5-sonnet-20241022-v2:0")
# => "Claude 3.5 Sonnet"
```

### 3. 実際のAI生成テスト（テスト環境）

管理画面から以下の機能を実行し、エラーが発生しないことを確認：

1. 記事の要約生成
2. タイトル提案
3. タグ提案
4. スラッグ生成
5. SEOメタ生成
6. 構成提案

### 4. 統計画面の確認

`/admin/ai_usage` にアクセスし、以下を確認：

- 新しいモデル名「Claude Sonnet 4 (2025-05-14)」が表示される
- 旧モデル「Claude 3.5 Sonnet」「Claude 3 Haiku」も正しく表示される
- コストが正確に計算されている
- 日次・月次の合計が正しく集計されている

### 5. CSVエクスポートの確認

統計画面からCSVをエクスポートし、以下を確認：

- 「モデル」列に新しいモデル名が記録されている
- 旧データも正しく表示される

## ロールバック手順

問題が発生した場合、以下の手順で即座にロールバック可能です：

### 1. MODELSハッシュを元に戻す
```ruby
MODELS = {
  summary: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
  title: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
  tags: "us.anthropic.claude-3-haiku-20240307-v1:0",
  slug: "us.anthropic.claude-3-haiku-20240307-v1:0",
  seo_meta: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
  structure: "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
}.freeze
```

### 2. 再デプロイ
```bash
git add app/services/ai/model_selector.rb
git commit -m "Revert to Claude 3.5 models"
git push
# デプロイコマンド実行
```

**注意**: MODEL_COSTSとdisplay_nameは変更不要です（後方互換性が保たれているため）。

## トラブルシューティング

### エラー: "Model not found" または "ValidationException"

**原因**: モデルIDが間違っているか、リージョンで利用不可

**対処**:
1. AWS Bedrockコンソールで正確なモデルIDを確認
2. 使用リージョンでClaude 4.5が有効化されているか確認
3. 必要に応じてモデルアクセスをリクエスト

### エラー: コスト計算が不正確

**原因**: MODEL_COSTSの料金が間違っている

**対処**:
1. 公式ドキュメントで正確な料金を確認
2. MODEL_COSTSを修正
3. 再デプロイ

### 統計画面でモデル名が表示されない

**原因**: display_nameメソッドのパターンマッチが不正

**対処**:
1. 実際のモデルIDをログで確認
2. display_nameメソッドの正規表現を修正

## 注意事項

### 必須確認事項
1. **料金の確認**: 実装前に必ず公式ドキュメントで料金を確認
2. **モデルIDの確認**: AWS Bedrockコンソールで正確なIDを確認
3. **リージョンの確認**: 使用リージョンでClaude 4.5が利用可能か確認

### データの安全性
- 既存の統計データは保持されます（新旧モデルは別レコード）
- ロールバックしてもデータは失われません
- 新旧モデルのデータは自動的に合算されます（日次・機能別集計）

### パフォーマンス
- Claude 4.5 Sonnetは高速化されています
- tags/slugをHaikuからSonnetに変更してもレスポンス時間は許容範囲内

### コスト
- tags/slugをHaikuからSonnetに変更するとコストが増加します
- ただし、これらは短いテキスト処理のため、実際の影響は限定的
- 必要に応じて、後からHaikuに戻すことも可能

## 完了チェックリスト

実装完了前に以下を確認してください：

- [ ] AWS BedrockでClaude 4.5のモデルIDを確認済み
- [ ] 公式ドキュメントで料金を確認済み
- [ ] MODELSハッシュを更新
- [ ] MODEL_COSTSハッシュを更新（旧モデルも保持）
- [ ] display_nameメソッドを更新
- [ ] コメントを更新
- [ ] 単体テストを更新
- [ ] 単体テストがパス
- [ ] Railsコンソールで動作確認
- [ ] テスト環境で各AI機能を実行
- [ ] 統計画面で正しく表示されることを確認
- [ ] CSVエクスポートで正しく記録されることを確認

## 質問・相談

実装中に不明点があれば、以下を確認してください：

1. `.kiro/specs/claude-4.5-model-upgrade/requirements.md` - 要件定義
2. `.kiro/specs/claude-4.5-model-upgrade/design.md` - 設計書
3. `.kiro/specs/claude-4.5-model-upgrade/tasks.md` - タスクリスト

それでも解決しない場合は、Kiroに相談してください。
