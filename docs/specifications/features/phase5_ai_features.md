# AI支援機能（記事作成・SEO最適化）仕様書

## 📅 作成日・更新日
- **作成日**: 2024-12-26
- **最終更新**: 2024-12-26
- **ステータス**: 🔵 実装待ち（Phase5.2予定）

---

## 🎯 概要

### 目的
Amazon Bedrockを活用したAI機能により、記事作成とSEO最適化を支援する。
記事の要約生成、タグ付け、URLスラッグ生成、SEOメタデータ生成を自動化し、
執筆者の負担を軽減しながら高品質なコンテンツ作成を実現する。

### ユーザーストーリー
- 執筆者として、記事の要約を自動生成したい、なぜなら時間を節約したいから
- 執筆者として、適切なタグを提案してほしい、なぜなら最適なタグ選択が難しいから
- 執筆者として、SEOに最適化されたメタデータを生成したい、なぜなら検索順位を上げたいから
- 執筆者として、URLスラッグを自動生成したい、なぜなら適切なURL構造を考えるのが面倒だから
- 執筆者として、記事の構成を提案してほしい、なぜなら論理的な構成を作るのが難しいから

---

## ✅ 要件

### 機能要件

#### 1. 記事要約生成
- [ ] 記事本文から自動要約生成（excerpt用）
- [ ] 要約の長さ指定（短い/中/長い）
- [ ] 複数の要約候補生成
- [ ] 要約の編集・調整機能
- [ ] 生成履歴の保存

#### 2. タグ自動提案
- [ ] 記事内容からタグ候補を抽出
- [ ] 既存タグとのマッチング
- [ ] 新規タグの提案
- [ ] タグの関連度スコア表示
- [ ] 複数タグの一括適用
- [ ] タグ数の推奨（3-5個）

#### 3. URLスラッグ自動生成
- [ ] 記事タイトルから適切なスラッグ生成
- [ ] 英語スラッグの生成（日本語タイトル対応）
- [ ] SEOフレンドリーな形式（小文字・ハイフン区切り）
- [ ] 重複チェック機能
- [ ] 複数候補の提案
- [ ] 手動編集可能

#### 4. SEOメタデータ生成
- [ ] メタディスクリプション自動生成（160文字以内）
- [ ] メタキーワード抽出
- [ ] OGタイトル生成
- [ ] OG説明文生成
- [ ] Twitter Card用テキスト生成
- [ ] 構造化データ用情報抽出

#### 5. 記事構成提案
- [ ] 記事テーマから構成案を生成
- [ ] 見出し構造の提案
- [ ] 各セクションの内容案
- [ ] 推奨文字数の提示
- [ ] 関連トピックの提案

#### 6. キーワード分析
- [ ] 主要キーワードの抽出
- [ ] 関連キーワードの提案
- [ ] キーワード密度の分析
- [ ] 競合キーワードの提案
- [ ] ロングテールキーワードの発見

#### 7. AI処理管理
- [ ] 処理状況の表示（ローディング）
- [ ] エラーハンドリング
- [ ] リトライ機能
- [ ] 処理履歴の保存
- [ ] コスト管理（API使用量追跡）

### 非機能要件
- **パフォーマンス**: 
  - 要約生成 < 10秒
  - タグ提案 < 5秒
  - スラッグ生成 < 3秒
- **精度**: 
  - タグ提案の適合率 > 80%
  - 要約の品質（人間評価）> 4/5
- **コスト管理**: 
  - 月間API使用量の監視
  - 使用量アラート機能
- **セキュリティ**: 
  - IAMロール認証
  - API キーの安全な管理
  - 記事内容の機密性保護

---

## 🖼️ 画面仕様

### UI/UX詳細

#### 記事編集画面（AI支援機能追加）

```
┌─────────────────────────────────────────────────────────────┐
│ 記事編集                                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ タイトル                                                    │
│ [Railsで始めるWeb開発                                    ] │
│                                                             │
│ URLスラッグ                                                 │
│ [rails-web-development                ] [🤖 AI生成]        │
│                                                             │
│ 本文（Markdown）                                            │
│ ┌─────────────────────────────────────────────────────┐   │
│ │ # Railsとは                                         │   │
│ │                                                     │   │
│ │ Railsは強力なWebフレームワークです...               │   │
│ │                                                     │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ 🤖 AI支援機能                                              │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                             │
│ 抜粋                                                        │
│ [                                                        ] │
│ [🤖 要約を生成] [短い] [中] [長い]                         │
│                                                             │
│ タグ                                                        │
│ [Ruby, Rails, プログラミング                            ] │
│ [🤖 タグを提案]                                            │
│                                                             │
│ 💡 AI提案タグ（クリックで追加）:                           │
│ [+ Web開発 (95%)] [+ MVC (88%)] [+ フレームワーク (82%)]  │
│                                                             │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ SEO設定                                                     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                             │
│ メタディスクリプション                                      │
│ [                                                        ] │
│ [🤖 自動生成]                                              │
│                                                             │
│ メタキーワード                                              │
│ [                                                        ] │
│ [🤖 キーワード抽出]                                        │
│                                                             │
│ OGタイトル                                                  │
│ [                                                        ] │
│ [🤖 自動生成]                                              │
│                                                             │
│ [保存] [プレビュー]                                         │
└─────────────────────────────────────────────────────────────┘
```

#### AI処理モーダル

```
┌─────────────────────────────────────────────────────────────┐
│ AI処理中...                                       [✕ 閉じる] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 🤖 記事を分析しています...                                  │
│                                                             │
│ ┌─────────────────────────────────────────────────────┐   │
│ │ ████████████████████░░░░░░░░░░░░ 60%               │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                             │
│ ✓ 記事内容の解析完了                                       │
│ ✓ キーワード抽出完了                                       │
│ ⏳ 要約生成中...                                           │
│ ⏳ タグ提案生成中...                                       │
│                                                             │
│ 推定残り時間: 約5秒                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### AI生成結果モーダル

```
┌─────────────────────────────────────────────────────────────┐
│ AI生成結果                                        [✕ 閉じる] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 📝 要約候補（3つ）                                          │
│                                                             │
│ ○ 短い版（80文字）                                         │
│   Railsは強力なWebフレームワークで、MVCアーキテクチャを    │
│   採用し、効率的な開発を実現します。                       │
│   [この要約を使用]                                          │
│                                                             │
│ ○ 中版（120文字）                                          │
│   Railsは強力なWebフレームワークで、MVCアーキテクチャを    │
│   採用しています。Convention over Configurationの思想に    │
│   基づき、効率的な開発を実現します。                       │
│   [この要約を使用]                                          │
│                                                             │
│ ○ 長い版（160文字）                                        │
│   Railsは強力なWebフレームワークで、MVCアーキテクチャを    │
│   採用しています。Convention over Configurationの思想に    │
│   基づき、効率的な開発を実現します。豊富なgemエコシステム │
│   により、様々な機能を簡単に追加できます。                 │
│   [この要約を使用]                                          │
│                                                             │
│ 🏷️ 提案タグ（関連度順）                                    │
│                                                             │
│ ☑ Ruby (98%)                                               │
│ ☑ Rails (95%)                                              │
│ ☑ Web開発 (92%)                                            │
│ ☐ MVC (88%)                                                │
│ ☐ フレームワーク (85%)                                     │
│ ☐ プログラミング (80%)                                     │
│                                                             │
│ 🔗 URLスラッグ候補                                          │
│                                                             │
│ ○ rails-web-development                                    │
│ ○ getting-started-with-rails                               │
│ ○ rails-framework-guide                                    │
│                                                             │
│ [選択したものを適用] [キャンセル]                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ データ仕様

### 使用するモデル

#### AiGeneration（新規作成）
AI生成履歴を管理

```ruby
create_table :ai_generations do |t|
  t.references :article, foreign_key: true
  t.references :admin_user, foreign_key: true
  t.string :generation_type  # 'summary', 'tags', 'slug', 'seo_meta', 'structure'
  t.text :input_content
  t.jsonb :output_data
  t.string :model_used       # 'claude-3-5-sonnet', 'claude-3-haiku'
  t.integer :tokens_used
  t.decimal :cost, precision: 10, scale: 6
  t.string :status           # 'pending', 'completed', 'failed'
  t.text :error_message
  t.timestamps
end

add_index :ai_generations, :article_id
add_index :ai_generations, :generation_type
add_index :ai_generations, :created_at
add_index :ai_generations, :status
```

#### AiUsageStats（新規作成）
API使用量統計

```ruby
create_table :ai_usage_stats do |t|
  t.date :date, null: false
  t.string :model_name
  t.integer :total_requests, default: 0
  t.integer :total_tokens, default: 0
  t.decimal :total_cost, precision: 10, scale: 2, default: 0
  t.jsonb :breakdown, default: {}  # 機能別の内訳
  t.timestamps
end

add_index :ai_usage_stats, [:date, :model_name], unique: true
```

### データフロー

```
1. ユーザーがAI機能をリクエスト
   ↓
2. 記事内容を取得・前処理
   ↓
3. Amazon Bedrockにリクエスト送信
   ↓
4. レスポンス受信・解析
   ↓
5. AiGenerationレコード作成
   ↓
6. 結果をユーザーに表示
   ↓
7. ユーザーが結果を選択・適用
   ↓
8. 記事データ更新
   ↓
9. AiUsageStats更新（日次集計）
```

### Amazon Bedrockモデル選択

```ruby
# app/services/ai/model_selector.rb
module Ai
  class ModelSelector
    MODELS = {
      summary: 'anthropic.claude-3-5-sonnet-20241022-v2:0',  # 高品質な要約
      tags: 'anthropic.claude-3-haiku-20240307-v1:0',        # 高速なタグ抽出
      slug: 'anthropic.claude-3-haiku-20240307-v1:0',        # 高速なスラッグ生成
      seo_meta: 'anthropic.claude-3-5-sonnet-20241022-v2:0', # 高品質なSEO文
      structure: 'anthropic.claude-3-5-sonnet-20241022-v2:0' # 構成提案
    }
    
    def self.select(generation_type)
      MODELS[generation_type.to_sym]
    end
  end
end
```

---

## 🔌 API仕様

### エンドポイント

```
POST   /admin/articles/:id/ai/generate_summary    # 要約生成
POST   /admin/articles/:id/ai/suggest_tags        # タグ提案
POST   /admin/articles/:id/ai/generate_slug       # スラッグ生成
POST   /admin/articles/:id/ai/generate_seo_meta   # SEOメタデータ生成
POST   /admin/articles/:id/ai/suggest_structure   # 構成提案
GET    /admin/ai/usage_stats                      # 使用量統計
```

### リクエスト・レスポンス例

#### 要約生成

**リクエスト**:
```json
POST /admin/articles/:id/ai/generate_summary

{
  "length": "medium",  // "short", "medium", "long"
  "count": 3           // 生成する候補数
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "summaries": [
      {
        "text": "Railsは強力なWebフレームワークで、MVCアーキテクチャを採用し、効率的な開発を実現します。",
        "length": 80,
        "type": "short"
      },
      {
        "text": "Railsは強力なWebフレームワークで、MVCアーキテクチャを採用しています。Convention over Configurationの思想に基づき、効率的な開発を実現します。",
        "length": 120,
        "type": "medium"
      },
      {
        "text": "Railsは強力なWebフレームワークで、MVCアーキテクチャを採用しています。Convention over Configurationの思想に基づき、効率的な開発を実現します。豊富なgemエコシステムにより、様々な機能を簡単に追加できます。",
        "length": 160,
        "type": "long"
      }
    ],
    "generation_id": 123,
    "tokens_used": 450,
    "cost": 0.0023
  }
}
```

#### タグ提案

**リクエスト**:
```json
POST /admin/articles/:id/ai/suggest_tags

{
  "max_tags": 6,
  "include_existing": true
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "suggested_tags": [
      {
        "name": "Ruby",
        "confidence": 0.98,
        "existing": true,
        "tag_id": 1
      },
      {
        "name": "Rails",
        "confidence": 0.95,
        "existing": true,
        "tag_id": 2
      },
      {
        "name": "Web開発",
        "confidence": 0.92,
        "existing": true,
        "tag_id": 5
      },
      {
        "name": "MVC",
        "confidence": 0.88,
        "existing": false,
        "tag_id": null
      },
      {
        "name": "フレームワーク",
        "confidence": 0.85,
        "existing": true,
        "tag_id": 8
      }
    ],
    "generation_id": 124,
    "tokens_used": 320,
    "cost": 0.0016
  }
}
```

#### スラッグ生成

**リクエスト**:
```json
POST /admin/articles/:id/ai/generate_slug

{
  "title": "Railsで始めるWeb開発",
  "count": 3
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "slugs": [
      {
        "slug": "rails-web-development",
        "available": true,
        "seo_score": 95
      },
      {
        "slug": "getting-started-with-rails",
        "available": true,
        "seo_score": 88
      },
      {
        "slug": "rails-framework-guide",
        "available": false,
        "seo_score": 82
      }
    ],
    "generation_id": 125,
    "tokens_used": 180,
    "cost": 0.0009
  }
}
```

#### SEOメタデータ生成

**リクエスト**:
```json
POST /admin/articles/:id/ai/generate_seo_meta

{
  "fields": ["meta_description", "meta_keywords", "og_title", "og_description"]
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "meta_description": "Railsの基礎から実践まで。MVCアーキテクチャとConvention over Configurationの思想を理解し、効率的なWeb開発を始めましょう。",
    "meta_keywords": "Rails, Ruby, Web開発, MVC, フレームワーク, プログラミング",
    "og_title": "Railsで始めるWeb開発 - 初心者から実践まで",
    "og_description": "Railsの基礎から実践まで学べる完全ガイド。MVCアーキテクチャの理解から実際のアプリケーション開発まで、ステップバイステップで解説します。",
    "generation_id": 126,
    "tokens_used": 520,
    "cost": 0.0026
  }
}
```

---

## 🧪 受け入れ基準

実装完了の判断基準：

### 要約生成
- [ ] 記事本文から適切な要約が生成される
- [ ] 短い/中/長いの3種類の長さで生成できる
- [ ] 複数の候補が提示される
- [ ] 生成された要約を選択して適用できる
- [ ] 生成時間が10秒以内

### タグ提案
- [ ] 記事内容から適切なタグが提案される
- [ ] 既存タグとマッチングされる
- [ ] 新規タグも提案される
- [ ] 関連度スコアが表示される
- [ ] 提案タグをクリックで追加できる
- [ ] 生成時間が5秒以内

### URLスラッグ生成
- [ ] 記事タイトルから適切なスラッグが生成される
- [ ] 日本語タイトルから英語スラッグが生成される
- [ ] SEOフレンドリーな形式（小文字・ハイフン区切り）
- [ ] 重複チェックが機能する
- [ ] 複数候補が提示される
- [ ] 生成時間が3秒以内

### SEOメタデータ生成
- [ ] メタディスクリプションが160文字以内で生成される
- [ ] メタキーワードが適切に抽出される
- [ ] OGタイトルが生成される
- [ ] OG説明文が生成される
- [ ] 生成されたメタデータを適用できる

### 記事構成提案
- [ ] 記事テーマから構成案が生成される
- [ ] 見出し構造が提案される
- [ ] 各セクションの内容案が提示される
- [ ] 推奨文字数が表示される

### エラーハンドリング
- [ ] API エラー時に適切なエラーメッセージが表示される
- [ ] リトライ機能が動作する
- [ ] タイムアウト処理が適切
- [ ] ネットワークエラー時の対応が適切

### コスト管理
- [ ] API使用量が記録される
- [ ] トークン数が記録される
- [ ] コストが計算される
- [ ] 使用量統計が表示される
- [ ] 月間使用量の上限設定が機能する

### UI/UX
- [ ] AI処理中のローディング表示が適切
- [ ] 処理進捗が表示される
- [ ] 生成結果が分かりやすく表示される
- [ ] 結果の選択・適用が簡単
- [ ] モバイル表示が適切

---

## 🧪 テスト仕様

### TDD適用判断

- [x] TDD適用: はい
- **理由**: 外部API依存、モック必須、コスト管理が重要なため

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Service | `app/services/ai/bedrock_client.rb` | `spec/services/ai/bedrock_client_spec.rb` |
| Service | `app/services/ai/summary_generator.rb` | `spec/services/ai/summary_generator_spec.rb` |
| Service | `app/services/ai/tag_suggester.rb` | `spec/services/ai/tag_suggester_spec.rb` |
| Service | `app/services/ai/slug_generator.rb` | `spec/services/ai/slug_generator_spec.rb` |
| Service | `app/services/ai/usage_tracker.rb` | `spec/services/ai/usage_tracker_spec.rb` |
| Model | `app/models/ai_generation.rb` | `spec/models/ai_generation_spec.rb` |
| Controller | `app/controllers/admin/ai_controller.rb` | `spec/controllers/admin/ai_controller_spec.rb` |

### Service: Ai::BedrockClient

#### describe '#invoke_model'

**正常系**:
- [ ] モデルを呼び出してレスポンスを返す
- [ ] レスポンスを正しくパースする
- [ ] トークン使用量を返す

**異常系**:
- [ ] API エラー時に例外を発生させる
- [ ] レート制限エラーを適切に処理する
- [ ] タイムアウトエラーを適切に処理する
- [ ] ネットワークエラーを適切に処理する

### Service: Ai::SummaryGenerator

#### describe '#generate'

**正常系**:
- [ ] 記事から要約を生成する
- [ ] 指定した長さの要約を生成する（short/medium/long）
- [ ] 複数の要約候補を返す
- [ ] 生成履歴を保存する

**異常系**:
- [ ] 記事内容が空の場合、エラーを返す
- [ ] API エラー時に適切なエラーメッセージを返す

### Service: Ai::TagSuggester

#### describe '#suggest'

**正常系**:
- [ ] 記事からタグを提案する
- [ ] 既存タグとマッチングする
- [ ] 信頼度スコアを返す
- [ ] 指定した数のタグを返す

**異常系**:
- [ ] 記事内容が空の場合、エラーを返す
- [ ] 既存タグが存在しない場合でも動作する

### Service: Ai::UsageTracker

#### describe '#track'

**正常系**:
- [ ] トークン使用量を記録する
- [ ] コストを計算する
- [ ] 日次統計を更新する
- [ ] 生成履歴を更新する

**異常系**:
- [ ] 不正なモデルIDの場合、コストを0として記録する

### テストコード例

```ruby
# spec/services/ai/bedrock_client_spec.rb
require 'rails_helper'

RSpec.describe Ai::BedrockClient do
  let(:client) { described_class.new }
  let(:model_id) { 'anthropic.claude-3-haiku-20240307-v1:0' }
  let(:prompt) { 'テストプロンプト' }
  
  describe '#invoke_model' do
    context '正常系' do
      it 'モデルを呼び出してレスポンスを返す' do
        # モック設定
        bedrock_client = instance_double(Aws::BedrockRuntime::Client)
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
        
        response_body = {
          'content' => [{ 'text' => '生成されたテキスト' }],
          'usage' => {
            'input_tokens' => 100,
            'output_tokens' => 50
          }
        }.to_json
        
        response = double(body: StringIO.new(response_body))
        allow(bedrock_client).to receive(:invoke_model).and_return(response)
        
        # 実行
        result = client.invoke_model(model_id, prompt)
        
        # 検証
        expect(result[:content]).to eq('生成されたテキスト')
        expect(result[:usage][:input_tokens]).to eq(100)
        expect(result[:usage][:output_tokens]).to eq(50)
      end
    end
    
    context '異常系' do
      it 'API エラー時に例外を発生させる' do
        bedrock_client = instance_double(Aws::BedrockRuntime::Client)
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
        allow(bedrock_client).to receive(:invoke_model).and_raise(
          Aws::BedrockRuntime::Errors::ServiceError.new(nil, 'API Error')
        )
        
        expect {
          client.invoke_model(model_id, prompt)
        }.to raise_error(Ai::BedrockError)
      end
      
      it 'レート制限エラーを適切に処理する' do
        bedrock_client = instance_double(Aws::BedrockRuntime::Client)
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
        allow(bedrock_client).to receive(:invoke_model).and_raise(
          Aws::BedrockRuntime::Errors::ThrottlingException.new(nil, 'Rate limit exceeded')
        )
        
        expect {
          client.invoke_model(model_id, prompt)
        }.to raise_error(Ai::RateLimitError)
      end
    end
  end
end
```

```ruby
# spec/services/ai/summary_generator_spec.rb
require 'rails_helper'

RSpec.describe Ai::SummaryGenerator do
  let(:generator) { described_class.new }
  let(:article) { create(:article, title: 'Ruby on Rails入門', content: 'Railsは強力なWebフレームワークです。' * 50) }
  let(:bedrock_client) { instance_double(Ai::BedrockClient) }
  
  before do
    allow(Ai::BedrockClient).to receive(:new).and_return(bedrock_client)
  end
  
  describe '#generate' do
    context '正常系' do
      it '記事から要約を生成する' do
        response = {
          content: {
            'summaries' => [
              { 'text' => '要約1', 'length' => 80 },
              { 'text' => '要約2', 'length' => 80 },
              { 'text' => '要約3', 'length' => 80 }
            ]
          }.to_json,
          usage: { input_tokens: 500, output_tokens: 200 }
        }
        
        allow(bedrock_client).to receive(:invoke_model).and_return(response)
        
        result = generator.generate(article, length: 'short')
        
        expect(result[:summaries].count).to eq(3)
        expect(result[:summaries].first[:text]).to eq('要約1')
      end
      
      it '指定した長さの要約を生成する' do
        allow(bedrock_client).to receive(:invoke_model) do |model_id, prompt|
          expect(prompt).to include('80文字以内')
          {
            content: { 'summaries' => [{ 'text' => '短い要約', 'length' => 80 }] }.to_json,
            usage: { input_tokens: 500, output_tokens: 100 }
          }
        end
        
        generator.generate(article, length: 'short')
      end
      
      it '生成履歴を保存する' do
        response = {
          content: { 'summaries' => [{ 'text' => '要約', 'length' => 80 }] }.to_json,
          usage: { input_tokens: 500, output_tokens: 100 }
        }
        
        allow(bedrock_client).to receive(:invoke_model).and_return(response)
        
        expect {
          generator.generate(article)
        }.to change(AiGeneration, :count).by(1)
        
        generation = AiGeneration.last
        expect(generation.generation_type).to eq('summary')
        expect(generation.article).to eq(article)
      end
    end
    
    context '異常系' do
      it '記事内容が空の場合、エラーを返す' do
        empty_article = create(:article, title: 'タイトル', content: '')
        
        expect {
          generator.generate(empty_article)
        }.to raise_error(ArgumentError, /記事内容が空です/)
      end
      
      it 'API エラー時に適切なエラーメッセージを返す' do
        allow(bedrock_client).to receive(:invoke_model).and_raise(Ai::BedrockError, 'API Error')
        
        expect {
          generator.generate(article)
        }.to raise_error(Ai::BedrockError)
      end
    end
  end
end
```

```ruby
# spec/services/ai/usage_tracker_spec.rb
require 'rails_helper'

RSpec.describe Ai::UsageTracker do
  let(:tracker) { described_class.new }
  let(:model_id) { 'anthropic.claude-3-haiku-20240307-v1:0' }
  let(:generation) { create(:ai_generation, status: 'pending') }
  let(:usage) { { input_tokens: 1000, output_tokens: 500 } }
  
  describe '#track' do
    context '正常系' do
      it 'トークン使用量を記録する' do
        tracker.track(generation.id, model_id, usage)
        
        generation.reload
        expect(generation.tokens_used).to eq(1500)
        expect(generation.status).to eq('completed')
      end
      
      it 'コストを計算する' do
        tracker.track(generation.id, model_id, usage)
        
        generation.reload
        # Haiku: input $0.00025/1K, output $0.00125/1K
        expected_cost = (1000 * 0.00025 / 1000) + (500 * 0.00125 / 1000)
        expect(generation.cost).to be_within(0.000001).of(expected_cost)
      end
      
      it '日次統計を更新する' do
        expect {
          tracker.track(generation.id, model_id, usage)
        }.to change { AiUsageStat.where(date: Date.today, model_name: model_id).count }.by(1)
        
        stat = AiUsageStat.find_by(date: Date.today, model_name: model_id)
        expect(stat.total_requests).to eq(1)
        expect(stat.total_tokens).to eq(1500)
      end
    end
    
    context '異常系' do
      it '不正なモデルIDの場合、コストを0として記録する' do
        tracker.track(generation.id, 'invalid-model-id', usage)
        
        generation.reload
        expect(generation.cost).to eq(0)
      end
    end
  end
end
```

```ruby
# spec/models/ai_generation_spec.rb
require 'rails_helper'

RSpec.describe AiGeneration, type: :model do
  describe 'associations' do
    it { should belong_to(:article).optional }
    it { should belong_to(:admin_user) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:generation_type) }
    it { should validate_inclusion_of(:generation_type).in_array(%w[summary tags slug seo_meta structure]) }
    it { should validate_inclusion_of(:status).in_array(%w[pending completed failed]) }
  end
  
  describe 'scopes' do
    it 'completed scope returns only completed generations' do
      completed = create(:ai_generation, status: 'completed')
      pending = create(:ai_generation, status: 'pending')
      
      expect(AiGeneration.completed).to include(completed)
      expect(AiGeneration.completed).not_to include(pending)
    end
  end
end
```

```ruby
# spec/controllers/admin/ai_controller_spec.rb
require 'rails_helper'

RSpec.describe Admin::AiController, type: :controller do
  let(:admin_user) { create(:admin_user) }
  let(:article) { create(:article, admin_user: admin_user) }
  
  before do
    sign_in admin_user
  end
  
  describe 'POST #generate_summary' do
    let(:summary_generator) { instance_double(Ai::SummaryGenerator) }
    
    before do
      allow(Ai::SummaryGenerator).to receive(:new).and_return(summary_generator)
    end
    
    context '正常系' do
      it '要約を生成する' do
        result = {
          summaries: [
            { text: '要約1', length: 80 },
            { text: '要約2', length: 120 }
          ],
          generation_id: 1,
          tokens_used: 450,
          cost: 0.0023
        }
        
        allow(summary_generator).to receive(:generate).and_return(result)
        
        post :generate_summary, params: {
          article_id: article.id,
          length: 'medium',
          count: 3
        }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['summaries'].count).to eq(2)
      end
    end
    
    context '異常系' do
      it 'API エラー時にエラーレスポンスを返す' do
        allow(summary_generator).to receive(:generate).and_raise(Ai::BedrockError, 'API Error')
        
        post :generate_summary, params: {
          article_id: article.id,
          length: 'medium'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to include('API Error')
      end
    end
  end
end
```

### テストデータ（FactoryBot）

```ruby
# spec/factories/ai_generations.rb
FactoryBot.define do
  factory :ai_generation do
    association :article
    association :admin_user
    generation_type { 'summary' }
    input_content { 'テスト記事の内容' }
    output_data { { summaries: ['要約1', '要約2'] } }
    model_used { 'anthropic.claude-3-haiku-20240307-v1:0' }
    tokens_used { 1000 }
    cost { 0.001 }
    status { 'pending' }
    
    trait :completed do
      status { 'completed' }
    end
    
    trait :failed do
      status { 'failed' }
      error_message { 'API Error' }
    end
    
    trait :summary do
      generation_type { 'summary' }
    end
    
    trait :tags do
      generation_type { 'tags' }
      output_data { { tags: [{ name: 'Ruby', confidence: 0.95 }] } }
    end
  end
end

# spec/factories/ai_usage_stats.rb
FactoryBot.define do
  factory :ai_usage_stat do
    date { Date.today }
    model_name { 'anthropic.claude-3-haiku-20240307-v1:0' }
    total_requests { 10 }
    total_tokens { 15000 }
    total_cost { 0.05 }
    breakdown { { summary: 5, tags: 5 } }
  end
end
```

### モック設定ヘルパー

```ruby
# spec/support/ai_mocks.rb
module AiMocks
  def mock_bedrock_client(response_content:, tokens: { input: 100, output: 50 })
    bedrock_client = instance_double(Aws::BedrockRuntime::Client)
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
    
    response_body = {
      'content' => [{ 'text' => response_content }],
      'usage' => {
        'input_tokens' => tokens[:input],
        'output_tokens' => tokens[:output]
      }
    }.to_json
    
    response = double(body: StringIO.new(response_body))
    allow(bedrock_client).to receive(:invoke_model).and_return(response)
    
    bedrock_client
  end
  
  def mock_bedrock_error(error_class: Aws::BedrockRuntime::Errors::ServiceError, message: 'API Error')
    bedrock_client = instance_double(Aws::BedrockRuntime::Client)
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
    allow(bedrock_client).to receive(:invoke_model).and_raise(error_class.new(nil, message))
    
    bedrock_client
  end
end

RSpec.configure do |config|
  config.include AiMocks
end
```

### カバレッジ目標

- Service: 95%以上
- Model: 95%以上
- Controller: 90%以上

---

## 💡 実装メモ

### 実装対象ファイル

#### バックエンド

1. **コントローラー**: `app/controllers/admin/ai_controller.rb`
   - AI機能のエンドポイント
   - リクエスト処理・レスポンス生成

2. **サービス**: `app/services/ai/`
   - `bedrock_client.rb` - Amazon Bedrock接続
   - `summary_generator.rb` - 要約生成
   - `tag_suggester.rb` - タグ提案
   - `slug_generator.rb` - スラッグ生成
   - `seo_meta_generator.rb` - SEOメタデータ生成
   - `structure_suggester.rb` - 構成提案
   - `usage_tracker.rb` - 使用量追跡

3. **モデル**: 
   - `app/models/ai_generation.rb` - 生成履歴
   - `app/models/ai_usage_stat.rb` - 使用量統計

4. **ジョブ**: `app/jobs/ai/`
   - `generate_summary_job.rb` - 非同期要約生成
   - `update_usage_stats_job.rb` - 使用量統計更新

#### フロントエンド

1. **JavaScript**: `app/javascript/controllers/ai/`
   - `assistant_controller.js` - AI支援機能統合
   - `summary_controller.js` - 要約生成UI
   - `tag_suggester_controller.js` - タグ提案UI
   - `slug_generator_controller.js` - スラッグ生成UI
   - `seo_meta_controller.js` - SEOメタデータUI

2. **ビュー**: `app/views/admin/ai/`
   - `_summary_modal.html.erb` - 要約生成モーダル
   - `_tag_suggestions.html.erb` - タグ提案表示
   - `_slug_candidates.html.erb` - スラッグ候補表示
   - `_seo_meta_form.html.erb` - SEOメタデータフォーム

### Amazon Bedrock統合

```ruby
# app/services/ai/bedrock_client.rb
require 'aws-sdk-bedrockruntime'

module Ai
  class BedrockClient
    def initialize
      @client = Aws::BedrockRuntime::Client.new(
        region: ENV['AWS_REGION'] || 'us-east-1',
        credentials: Aws::InstanceProfileCredentials.new
      )
    end
    
    def invoke_model(model_id, prompt, max_tokens: 2000)
      request_body = {
        anthropic_version: "bedrock-2023-05-31",
        max_tokens: max_tokens,
        messages: [
          {
            role: "user",
            content: prompt
          }
        ]
      }
      
      response = @client.invoke_model({
        model_id: model_id,
        body: request_body.to_json,
        content_type: 'application/json',
        accept: 'application/json'
      })
      
      parse_response(response)
    rescue Aws::BedrockRuntime::Errors::ServiceError => e
      handle_error(e)
    end
    
    private
    
    def parse_response(response)
      body = JSON.parse(response.body.read)
      {
        content: body['content'][0]['text'],
        usage: {
          input_tokens: body['usage']['input_tokens'],
          output_tokens: body['usage']['output_tokens']
        }
      }
    end
    
    def handle_error(error)
      Rails.logger.error("Bedrock API Error: #{error.message}")
      raise Ai::BedrockError, error.message
    end
  end
end
```

### プロンプト設計

#### 要約生成プロンプト

```ruby
# app/services/ai/summary_generator.rb
module Ai
  class SummaryGenerator
    def generate(article, length: 'medium')
      prompt = build_prompt(article, length)
      model_id = ModelSelector.select(:summary)
      
      response = bedrock_client.invoke_model(model_id, prompt)
      
      parse_summaries(response[:content])
    end
    
    private
    
    def build_prompt(article, length)
      max_chars = {
        'short' => 80,
        'medium' => 120,
        'long' => 160
      }[length]
      
      <<~PROMPT
        以下の記事の要約を#{max_chars}文字以内で3つ生成してください。
        
        記事タイトル: #{article.title}
        
        記事本文:
        #{article.content}
        
        要件:
        - 記事の主要なポイントを簡潔にまとめる
        - #{max_chars}文字以内に収める
        - 読者の興味を引く表現を使う
        - 3つの異なる視点から要約を作成
        
        出力形式（JSON）:
        {
          "summaries": [
            {"text": "要約1", "length": 文字数},
            {"text": "要約2", "length": 文字数},
            {"text": "要約3", "length": 文字数}
          ]
        }
      PROMPT
    end
  end
end
```

#### タグ提案プロンプト

```ruby
# app/services/ai/tag_suggester.rb
module Ai
  class TagSuggester
    def suggest(article, max_tags: 6)
      prompt = build_prompt(article, max_tags)
      model_id = ModelSelector.select(:tags)
      
      response = bedrock_client.invoke_model(model_id, prompt, max_tokens: 1000)
      
      match_existing_tags(parse_tags(response[:content]))
    end
    
    private
    
    def build_prompt(article, max_tags)
      existing_tags = Tag.pluck(:name).join(', ')
      
      <<~PROMPT
        以下の記事に適したタグを#{max_tags}個提案してください。
        
        記事タイトル: #{article.title}
        記事本文: #{article.content}
        
        既存のタグ: #{existing_tags}
        
        要件:
        - 記事の内容を的確に表すタグを選ぶ
        - 既存のタグを優先的に使用する
        - 必要に応じて新しいタグを提案する
        - 関連度の高い順に並べる
        - 各タグに0-1の信頼度スコアを付ける
        
        出力形式（JSON）:
        {
          "tags": [
            {"name": "タグ名", "confidence": 0.95},
            {"name": "タグ名", "confidence": 0.88}
          ]
        }
      PROMPT
    end
    
    def match_existing_tags(suggested_tags)
      suggested_tags.map do |tag_data|
        existing_tag = Tag.find_by('LOWER(name) = ?', tag_data[:name].downcase)
        tag_data.merge(
          existing: existing_tag.present?,
          tag_id: existing_tag&.id
        )
      end
    end
  end
end
```

#### URLスラッグ生成プロンプト

```ruby
# app/services/ai/slug_generator.rb
module Ai
  class SlugGenerator
    def generate(title, count: 3)
      prompt = build_prompt(title, count)
      model_id = ModelSelector.select(:slug)
      
      response = bedrock_client.invoke_model(model_id, prompt, max_tokens: 500)
      
      check_availability(parse_slugs(response[:content]))
    end
    
    private
    
    def build_prompt(title, count)
      <<~PROMPT
        以下の記事タイトルから、SEOに最適化されたURLスラッグを#{count}個生成してください。
        
        記事タイトル: #{title}
        
        要件:
        - 英語の小文字とハイフンのみ使用
        - 3-5単語程度
        - 記事の内容を的確に表す
        - SEOフレンドリー
        - 読みやすく覚えやすい
        
        出力形式（JSON）:
        {
          "slugs": [
            {"slug": "rails-web-development", "seo_score": 95},
            {"slug": "getting-started-with-rails", "seo_score": 88}
          ]
        }
      PROMPT
    end
    
    def check_availability(slugs)
      slugs.map do |slug_data|
        available = !Article.exists?(slug: slug_data[:slug])
        slug_data.merge(available: available)
      end
    end
  end
end
```

#### SEOメタデータ生成プロンプト

```ruby
# app/services/ai/seo_meta_generator.rb
module Ai
  class SeoMetaGenerator
    def generate(article)
      prompt = build_prompt(article)
      model_id = ModelSelector.select(:seo_meta)
      
      response = bedrock_client.invoke_model(model_id, prompt)
      
      parse_seo_meta(response[:content])
    end
    
    private
    
    def build_prompt(article)
      <<~PROMPT
        以下の記事のSEOメタデータを生成してください。
        
        記事タイトル: #{article.title}
        記事本文: #{article.content}
        
        生成するメタデータ:
        1. メタディスクリプション（160文字以内）
           - 記事の内容を簡潔に説明
           - 検索結果でクリックしたくなる表現
           - 主要キーワードを含める
        
        2. メタキーワード（6-8個、カンマ区切り）
           - 記事の主要なキーワード
           - 検索されやすいキーワード
        
        3. OGタイトル（60文字以内）
           - SNSシェア用のタイトル
           - 魅力的で興味を引く表現
        
        4. OG説明文（200文字以内）
           - SNSシェア用の説明文
           - 記事の価値を伝える
        
        出力形式（JSON）:
        {
          "meta_description": "説明文",
          "meta_keywords": "キーワード1, キーワード2, ...",
          "og_title": "OGタイトル",
          "og_description": "OG説明文"
        }
      PROMPT
    end
  end
end
```

### コスト管理

```ruby
# app/services/ai/usage_tracker.rb
module Ai
  class UsageTracker
    PRICING = {
      'anthropic.claude-3-5-sonnet-20241022-v2:0' => {
        input: 0.003 / 1000,   # $0.003 per 1K input tokens
        output: 0.015 / 1000   # $0.015 per 1K output tokens
      },
      'anthropic.claude-3-haiku-20240307-v1:0' => {
        input: 0.00025 / 1000, # $0.00025 per 1K input tokens
        output: 0.00125 / 1000 # $0.00125 per 1K output tokens
      }
    }
    
    def track(generation_id, model_id, usage)
      generation = AiGeneration.find(generation_id)
      
      input_tokens = usage[:input_tokens]
      output_tokens = usage[:output_tokens]
      total_tokens = input_tokens + output_tokens
      
      cost = calculate_cost(model_id, input_tokens, output_tokens)
      
      generation.update!(
        tokens_used: total_tokens,
        cost: cost,
        status: 'completed'
      )
      
      update_daily_stats(model_id, total_tokens, cost)
    end
    
    private
    
    def calculate_cost(model_id, input_tokens, output_tokens)
      pricing = PRICING[model_id]
      return 0 unless pricing
      
      (input_tokens * pricing[:input]) + (output_tokens * pricing[:output])
    end
    
    def update_daily_stats(model_id, tokens, cost)
      stat = AiUsageStat.find_or_create_by(
        date: Date.today,
        model_name: model_id
      )
      
      stat.increment!(:total_requests)
      stat.increment!(:total_tokens, tokens)
      stat.increment!(:total_cost, cost)
    end
  end
end
```

### エラーハンドリング

```ruby
# app/services/ai/error_handler.rb
module Ai
  class BedrockError < StandardError; end
  class RateLimitError < BedrockError; end
  class QuotaExceededError < BedrockError; end
  
  class ErrorHandler
    def handle(error, generation_id)
      case error
      when Aws::BedrockRuntime::Errors::ThrottlingException
        handle_rate_limit(generation_id)
      when Aws::BedrockRuntime::Errors::ServiceQuotaExceededException
        handle_quota_exceeded(generation_id)
      else
        handle_generic_error(error, generation_id)
      end
    end
    
    private
    
    def handle_rate_limit(generation_id)
      AiGeneration.find(generation_id).update!(
        status: 'failed',
        error_message: 'レート制限に達しました。しばらく待ってから再試行してください。'
      )
      raise RateLimitError
    end
    
    def handle_quota_exceeded(generation_id)
      AiGeneration.find(generation_id).update!(
        status: 'failed',
        error_message: '月間使用量の上限に達しました。'
      )
      raise QuotaExceededError
    end
  end
end
```

### フロントエンド実装（Stimulus）

```javascript
// app/javascript/controllers/ai/assistant_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["summaryButton", "tagsButton", "slugButton", "seoButton", "loading"]
  static values = {
    articleId: Number
  }
  
  // 要約生成
  async generateSummary(event) {
    event.preventDefault()
    this.showLoading("要約を生成中...")
    
    try {
      const response = await fetch(`/admin/articles/${this.articleIdValue}/ai/generate_summary`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          length: 'medium',
          count: 3
        })
      })
      
      const data = await response.json()
      this.showSummaryModal(data.data.summaries)
    } catch (error) {
      this.showError('要約生成に失敗しました')
    } finally {
      this.hideLoading()
    }
  }
  
  // タグ提案
  async suggestTags(event) {
    event.preventDefault()
    this.showLoading("タグを提案中...")
    
    try {
      const response = await fetch(`/admin/articles/${this.articleIdValue}/ai/suggest_tags`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          max_tags: 6,
          include_existing: true
        })
      })
      
      const data = await response.json()
      this.displayTagSuggestions(data.data.suggested_tags)
    } catch (error) {
      this.showError('タグ提案に失敗しました')
    } finally {
      this.hideLoading()
    }
  }
  
  // スラッグ生成
  async generateSlug(event) {
    event.preventDefault()
    const title = document.querySelector('#article_title').value
    
    if (!title) {
      this.showError('タイトルを入力してください')
      return
    }
    
    this.showLoading("スラッグを生成中...")
    
    try {
      const response = await fetch(`/admin/articles/${this.articleIdValue}/ai/generate_slug`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          title: title,
          count: 3
        })
      })
      
      const data = await response.json()
      this.showSlugModal(data.data.slugs)
    } catch (error) {
      this.showError('スラッグ生成に失敗しました')
    } finally {
      this.hideLoading()
    }
  }
  
  // SEOメタデータ生成
  async generateSeoMeta(event) {
    event.preventDefault()
    this.showLoading("SEOメタデータを生成中...")
    
    try {
      const response = await fetch(`/admin/articles/${this.articleIdValue}/ai/generate_seo_meta`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          fields: ['meta_description', 'meta_keywords', 'og_title', 'og_description']
        })
      })
      
      const data = await response.json()
      this.applySeoMeta(data.data)
    } catch (error) {
      this.showError('SEOメタデータ生成に失敗しました')
    } finally {
      this.hideLoading()
    }
  }
  
  // ヘルパーメソッド
  showLoading(message) {
    this.loadingTarget.textContent = message
    this.loadingTarget.classList.remove('hidden')
  }
  
  hideLoading() {
    this.loadingTarget.classList.add('hidden')
  }
  
  showError(message) {
    alert(message)
  }
  
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
  
  // モーダル表示
  showSummaryModal(summaries) {
    // モーダルを表示して要約候補を表示
    const modal = document.querySelector('#summary-modal')
    // ... モーダル表示ロジック
  }
  
  displayTagSuggestions(tags) {
    const container = document.querySelector('#tag-suggestions')
    container.innerHTML = tags.map(tag => `
      <button 
        class="tag-suggestion" 
        data-action="click->ai--assistant#addTag"
        data-tag-name="${tag.name}"
        data-tag-id="${tag.tag_id}">
        + ${tag.name} (${Math.round(tag.confidence * 100)}%)
      </button>
    `).join('')
  }
  
  addTag(event) {
    const tagName = event.target.dataset.tagName
    const tagId = event.target.dataset.tagId
    
    // タグ入力フィールドに追加
    const tagInput = document.querySelector('#article_tag_names')
    const currentTags = tagInput.value.split(',').map(t => t.trim()).filter(t => t)
    
    if (!currentTags.includes(tagName)) {
      currentTags.push(tagName)
      tagInput.value = currentTags.join(', ')
    }
    
    // ボタンを無効化
    event.target.disabled = true
    event.target.classList.add('opacity-50')
  }
  
  applySeoMeta(data) {
    document.querySelector('#article_meta_description').value = data.meta_description
    document.querySelector('#article_meta_keywords').value = data.meta_keywords
    document.querySelector('#article_og_title').value = data.og_title
    document.querySelector('#article_og_description').value = data.og_description
    
    this.showSuccess('SEOメタデータを適用しました')
  }
  
  showSuccess(message) {
    // 成功通知を表示
    const notification = document.createElement('div')
    notification.className = 'notification success'
    notification.textContent = message
    document.body.appendChild(notification)
    
    setTimeout(() => notification.remove(), 3000)
  }
}
```

### 必要なGem

```ruby
# Gemfile
gem 'aws-sdk-bedrockruntime', '~> 1.0'  # Amazon Bedrock SDK
```

### 環境変数

```bash
# .env
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key      # 開発環境のみ
AWS_SECRET_ACCESS_KEY=your_secret_key  # 開発環境のみ

# 本番環境ではIAMロールを使用（環境変数不要）

# AI機能の設定
AI_MONTHLY_QUOTA=100.00  # 月間使用量上限（USD）
AI_RATE_LIMIT=10         # 1分あたりのリクエスト数上限
```

### IAMポリシー（本番環境）

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel"
      ],
      "Resource": [
        "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
        "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
      ]
    }
  ]
}
```

---

## 📊 実装履歴

| 日付 | 担当 | 内容 |
|------|------|------|
| 2024-12-26 | Kiro | 初版作成（Phase5.2実装待ち） |

---

## 🔗 関連ドキュメント

- Phase計画書: `/docs/development/phase_plan_rails_8_1_1.md`
- 総合仕様書: `/docs/specifications/spec.md`
- Amazon Bedrock公式ドキュメント: https://docs.aws.amazon.com/bedrock/
- Claude API リファレンス: https://docs.anthropic.com/claude/reference/

---

## 📝 補足

### モデル選択の理由

| 機能 | モデル | 理由 |
|------|--------|------|
| 要約生成 | Claude 3.5 Sonnet | 高品質な文章生成が必要 |
| タグ提案 | Claude 3 Haiku | 高速処理が重要、精度も十分 |
| スラッグ生成 | Claude 3 Haiku | シンプルなタスク、高速処理 |
| SEOメタデータ | Claude 3.5 Sonnet | 高品質な文章生成が必要 |
| 構成提案 | Claude 3.5 Sonnet | 複雑な思考が必要 |

### コスト見積もり

**想定使用量（月間）**:
- 記事数: 20記事/月
- 1記事あたりのAI使用:
  - 要約生成: 1回（Sonnet）
  - タグ提案: 1回（Haiku）
  - スラッグ生成: 1回（Haiku）
  - SEOメタデータ: 1回（Sonnet）

**月間コスト試算**:
- Sonnet使用: 40回 × $0.05 = $2.00
- Haiku使用: 40回 × $0.01 = $0.40
- **合計: 約$2.40/月**

### 実装優先度
Phase 5.2での実装を予定。Phase 5.1（メディアライブラリ）完了後に着手する。

### 技術的制約
- Amazon Bedrockが利用可能なリージョン（us-east-1推奨）
- IAMロール設定が必要（本番環境）
- レート制限に注意（Claude 3.5 Sonnet: 10 req/min）
- トークン数制限（入力+出力で最大200K tokens）

### セキュリティ考慮事項
- 記事内容の機密性（公開前の記事も含む）
- API キーの安全な管理
- IAMロールの最小権限原則
- ログに機密情報を含めない

### パフォーマンス考慮事項
- 非同期処理の活用（長時間処理）
- キャッシュの活用（同じ記事の再生成）
- レート制限の遵守
- タイムアウト設定（30秒）

### 将来の拡張可能性
- 画像のalt属性自動生成
- 記事の自動校正機能
- 関連記事の自動提案
- カテゴリの自動分類
- 多言語翻訳機能
- 記事の品質スコアリング
- 競合分析機能
