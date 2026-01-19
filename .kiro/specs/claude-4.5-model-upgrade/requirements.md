# Claude 4.5 モデルアップグレード - 要件定義

## 1. プロジェクト概要

### 1.1 目的
記事作成で利用しているAIモデルをClaude 3.5/3 HaikuからClaude 4.5 Sonnet/Haikuに更新し、より高品質なコンテンツ生成を実現する。

### 1.2 背景
- 現在、記事の要約、タイトル提案、タグ抽出、SEOメタ生成などにClaude 3.5 Sonnet/Claude 3 Haikuを使用
- Claude 4.5の登場により、より高品質で効率的なコンテンツ生成が可能に
- 緊急対応として、最小限の変更で確実にアップグレードを実施

### 1.3 スコープ
**対象範囲:**
- `app/services/ai/model_selector.rb`のモデルID更新
- モデル表示名の更新
- コスト計算の更新（新モデルの料金体系に対応）
- AI使用統計の互換性確保

**対象外:**
- プロンプトの最適化（別タスクとして実施）
- 新機能の追加
- UIの変更

## 2. 現状分析

### 2.1 現在のモデル構成
```ruby
MODELS = {
  summary: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",    # 要約生成
  title: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",      # タイトル提案
  tags: "us.anthropic.claude-3-haiku-20240307-v1:0",          # タグ抽出
  slug: "us.anthropic.claude-3-haiku-20240307-v1:0",          # スラッグ生成
  seo_meta: "us.anthropic.claude-3-5-sonnet-20241022-v2:0",   # SEOメタ生成
  structure: "us.anthropic.claude-3-5-sonnet-20241022-v2:0"   # 構造提案
}
```

### 2.2 影響範囲
1. **ModelSelector** (`app/services/ai/model_selector.rb`)
   - モデルID定義
   - コスト計算
   - 表示名生成

2. **AiUsageStat** (`app/models/ai_usage_stat.rb`)
   - 日次統計の記録（モデル名がキーとして使用される）
   - 既存データとの互換性が必要

3. **AiGeneration** (`app/models/ai_generation.rb`)
   - 生成履歴の記録
   - モデル情報は直接保存されない（generation_typeのみ）

4. **UsageTracker** (`app/services/ai/usage_tracker.rb`)
   - 統計集計時にModelSelector.display_nameを使用
   - 新旧モデルの表示名を適切に処理する必要あり

## 3. 要件

### 3.1 機能要件

#### FR-1: モデルIDの更新
- **優先度**: 高
- **説明**: 全てのgeneration_typeで使用するモデルをClaude 4.5に更新
- **受け入れ基準**:
  1. Sonnetを使用する機能（summary, title, seo_meta, structure）がClaude 4.5 Sonnetを使用
  2. Haikuを使用する機能（tags, slug）がClaude 4.5 Haikuを使用（利用可能な場合）
  3. 既存のcross-region inference profile形式（us.プレフィックス）を維持

#### FR-2: コスト計算の更新
- **優先度**: 高
- **説明**: Claude 4.5の料金体系に対応したコスト計算
- **受け入れ基準**:
  1. 新モデルの正確な料金（input/output per 1M tokens）が設定される
  2. 既存のcalculate_costメソッドが新モデルで正しく動作
  3. 後方互換性のため、旧モデルIDのコスト情報も保持

#### FR-3: 表示名の更新
- **優先度**: 中
- **説明**: 管理画面やログで表示されるモデル名を更新
- **受け入れ基準**:
  1. 新モデルIDに対して適切な表示名（"Claude 4.5 Sonnet"等）を返す
  2. 旧モデルIDに対しても引き続き正しい表示名を返す（統計データの互換性）
  3. display_nameメソッドが新旧両方のモデルIDに対応

#### FR-4: 統計データの互換性
- **優先度**: 高
- **説明**: 既存のAI使用統計データとの互換性を保持
- **受け入れ基準**:
  1. 新モデルでの使用統計が正しく記録される
  2. 旧モデルの統計データが引き続き正しく表示される
  3. 月次・日次レポートで新旧モデルが区別して表示される

### 3.2 非機能要件

#### NFR-1: 後方互換性
- 既存のAI生成履歴データが引き続き正しく表示される
- 旧モデルIDを含む統計データが正しく集計される

#### NFR-2: デプロイメント
- ダウンタイムなしでデプロイ可能
- ロールバックが容易（設定ファイルの変更のみ）

#### NFR-3: モニタリング
- 新モデルの使用状況が既存の統計機能で追跡可能
- コスト計算が正確に行われることを確認可能

## 4. 技術的制約

### 4.1 AWS Bedrock制約
- Claude 4.5のモデルIDはAWS Bedrockのドキュメントに従う
- Cross-region inference profileを使用（us.プレフィックス）
- モデルの利用可能性はリージョンに依存

### 4.2 料金情報
- Claude 4.5の正確な料金情報を確認する必要あり
- 料金は予告なく変更される可能性があるため、設定として管理

### 4.3 データベース制約
- `ai_usage_stats.ai_model`カラムは文字列型
- 既存データとの整合性を保つため、モデルIDの形式を維持

## 5. リスクと対策

### 5.1 リスク
1. **モデルIDの誤り**: 誤ったモデルIDを設定するとAPI呼び出しが失敗
2. **料金の誤算**: 不正確な料金設定によりコスト管理が不正確になる
3. **統計の不整合**: 新旧モデルの統計が混在し、レポートが不正確になる

### 5.2 対策
1. AWS BedrockドキュメントでモデルIDを確認
2. 料金情報を公式ドキュメントで確認
3. テスト環境で動作確認後にデプロイ
4. display_nameメソッドで新旧モデルを適切に区別

## 6. 成功基準

### 6.1 必須条件
- [ ] 全てのAI生成機能がClaude 4.5を使用
- [ ] コスト計算が正確に動作
- [ ] 既存の統計データが正しく表示される
- [ ] 新しい使用統計が正しく記録される

### 6.2 検証方法
1. 各generation_typeで実際にAI生成を実行
2. 生成されたコンテンツの品質を確認
3. 管理画面で使用統計を確認
4. コスト計算の正確性を確認

## 7. タイムライン

- **要件定義**: 完了
- **設計**: 30分
- **実装**: 1時間
- **テスト**: 30分
- **デプロイ**: 即時

**総所要時間**: 約2時間（緊急対応）

## 8. 参考情報

### 8.1 関連ファイル
- `app/services/ai/model_selector.rb` - メインの更新対象
- `app/models/ai_usage_stat.rb` - 統計モデル
- `app/services/ai/usage_tracker.rb` - 統計トラッキング
- `app/models/ai_generation.rb` - 生成履歴

### 8.2 外部リソース
- AWS Bedrock Claude 4.5ドキュメント
- Anthropic料金ページ
- AWS Bedrock料金ページ
