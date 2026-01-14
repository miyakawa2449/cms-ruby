# Claude Code コンテキスト情報

## 🤖 Claude Codeの役割

**実装・設計担当**

### 主な責任範囲
1. **コード実装**
   - 機能仕様書に基づく実装
   - バグ修正
   - リファクタリング

2. **アーキテクチャ設計**
   - システム設計
   - データベース設計
   - API設計

3. **コード品質管理**
   - コーディング規約遵守
   - テストコード作成
   - パフォーマンス最適化

---

## 📋 作業フロー

### 1. 新機能実装時

#### Step 1: 仕様書確認
```
1. Kiroから指定された仕様書を読み込む
   - `/docs/specifications/features/[機能名].md`
2. 以下を確認
   - 機能要件・非機能要件
   - 画面仕様・データ仕様
   - API仕様（該当する場合）
   - 受け入れ基準
   - 実装メモ（Claude Codeへの指示）
```

#### Step 2: 実装計画
```
1. 必要なファイルを特定
   - モデル・コントローラー・ビュー
   - サービスクラス・ヘルパー
   - JavaScript・CSS
2. 既存実装を確認
   - 類似機能の実装方法
   - 使用しているgem・ライブラリ
3. データベース変更の確認
   - マイグレーションの必要性
```

#### Step 3: 実装
```
1. コーディング規約に従って実装
   - `/docs/handoff/conventions.md` 参照
2. 既存パターンを踏襲
   - Service Object Pattern
   - Fat Model解消
3. コメントを記述
   - 複雑なロジックには説明を追加
```

#### Step 4: 実装完了報告
```
1. 実装内容をKiroに報告
   - 変更ファイル一覧
   - 主要な変更内容
   - 注意点・確認してほしい点
2. 動作確認方法を伝える
```

### 2. バグ修正時

```
1. 問題点を特定
2. 原因を調査
3. 修正実装
4. 修正内容をKiroに報告
```

---

## 📚 参照ドキュメント

### 実装前に必ず確認
1. **機能仕様書**: `/docs/specifications/features/[機能名].md`
2. **コーディング規約**: `/docs/handoff/conventions.md`
3. **総合仕様書**: `/docs/specifications/spec.md`

### 必要に応じて確認
1. **Phase計画書**: `/docs/development/phase_plan_rails_8_1_1.md`
2. **データベース設計**: `/docs/database/schema_design_v2.md`
3. **API設計**: `/docs/api/api_design.md`

---

## 🏗️ アーキテクチャパターン

### Service Object Pattern
Fat Modelを避けるため、ビジネスロジックはServiceクラスに分離

```ruby
# app/services/article_publishing_service.rb
class ArticlePublishingService
  def initialize(article)
    @article = article
  end

  def publish
    # ビジネスロジック
  end
end
```

### Controller層
- 薄く保つ
- Serviceクラスに処理を委譲
- Strong Parametersで入力検証

```ruby
class Admin::ArticlesController < Admin::BaseController
  def publish
    service = ArticlePublishingService.new(@article)
    result = service.publish
    
    if result[:success]
      redirect_to admin_articles_path, notice: result[:message]
    else
      redirect_to admin_articles_path, alert: result[:message]
    end
  end
end
```

### Model層
- データ構造の定義
- バリデーション
- アソシエーション
- スコープ
- 複雑なビジネスロジックはServiceに委譲

---

## 🎨 フロントエンド

### Stimulus Controller
- JavaScriptはStimulusコントローラーで管理
- data-controller属性でHTML要素に紐付け

```javascript
// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  
  connect() {
    console.log("Controller connected")
  }
}
```

### Tailwind CSS
- ユーティリティクラスを使用
- カスタムスタイルは最小限に

---

## 🗄️ データベース

### マイグレーション
- 必ず可逆的に作成
- インデックスを適切に設定
- 外部キー制約を設定

```ruby
class CreateExamples < ActiveRecord::Migration[8.1]
  def change
    create_table :examples do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :examples, :name
  end
end
```

---

## 🧪 テスト

### RSpec
- モデル・コントローラー・サービスのテストを作成
- FactoryBotでテストデータ作成

```ruby
# spec/services/example_service_spec.rb
RSpec.describe ExampleService do
  describe '#execute' do
    it 'returns success' do
      service = ExampleService.new
      result = service.execute
      
      expect(result[:success]).to be true
    end
  end
end
```

---

## 🔒 セキュリティ

### 必須対応
1. **Strong Parameters**: 必ず使用
2. **CSRF対策**: Rails標準機能を活用
3. **認証・認可**: Devise + Pundit
4. **SQLインジェクション対策**: ActiveRecord ORMを使用
5. **XSS対策**: Rails標準エスケープ

---

## 💡 実装Tips

### 既存実装を参考にする
- 類似機能の実装を確認
- パターンを踏襲

### コメントを適切に記述
```ruby
# 複雑なロジックには説明を追加
# 例: N+1問題を回避するためincludes使用
@articles = Article.includes(:categories, :tags).published
```

### エラーハンドリング
```ruby
begin
  # 処理
rescue => e
  Rails.logger.error "Error: #{e.message}"
  { success: false, error: e.message }
end
```

### パフォーマンス
- N+1問題を避ける（includes, eager_load）
- 不要なクエリを避ける
- インデックスを適切に設定

---

## 📊 実装完了報告フォーマット

```markdown
## 実装完了: [機能名]

### 変更ファイル
- app/models/example.rb
- app/controllers/admin/examples_controller.rb
- app/views/admin/examples/_form.html.erb

### 主要な変更内容
1. Exampleモデル作成
2. CRUD機能実装
3. バリデーション追加

### 動作確認方法
1. 管理画面にログイン
2. Examplesメニューをクリック
3. 新規作成・編集・削除を確認

### 注意点
- 既存データへの影響なし
- マイグレーション実行が必要
```

---

**作成者**: Kiro  
**作成日**: 2025-12-26  
**最終更新**: 2025-12-26  
**バージョン**: 1.0
