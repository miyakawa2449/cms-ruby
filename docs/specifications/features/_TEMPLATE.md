# [機能名] 仕様書

## 📅 作成日・更新日
- **作成日**: YYYY-MM-DD
- **最終更新**: YYYY-MM-DD
- **ステータス**: 🟡 仕様策定中 / 🔵 実装待ち / 🟢 実装完了 / 🔴 保留

---

## 🎯 概要

### 目的
この機能が解決する課題や提供する価値を記述

### ユーザーストーリー
- ユーザーとして、〇〇したい、なぜなら〇〇だから

---

## ✅ 要件

### 機能要件
- [ ] 要件1: 具体的な機能内容
- [ ] 要件2: 具体的な機能内容
- [ ] 要件3: 具体的な機能内容

### 非機能要件
- **パフォーマンス**: レスポンスタイム、処理速度等
- **セキュリティ**: 認証、認可、データ保護等
- **アクセシビリティ**: WCAG準拠、キーボード操作等
- **SEO**: メタタグ、構造化データ等

---

## 🖼️ 画面仕様

### UI/UX詳細
- レイアウト説明
- インタラクション説明
- レスポンシブ対応

### ワイヤーフレーム
- 参照: `/docs/wireframes/...`

### 画面遷移
```
画面A → 画面B → 画面C
```

---

## 🗄️ データ仕様

### 使用するモデル
- **Model1**: 説明
- **Model2**: 説明

### 新規テーブル（必要な場合）
```ruby
create_table :table_name do |t|
  t.string :field1
  t.text :field2
  t.timestamps
end
```

### データフロー
```
入力 → 処理 → 出力
```

---

## 🔌 API仕様（該当する場合）

### エンドポイント
```
GET /api/v1/resource
POST /api/v1/resource
```

### リクエスト例
```json
{
  "field1": "value1",
  "field2": "value2"
}
```

### レスポンス例
```json
{
  "success": true,
  "data": {}
}
```

---

## 🧪 受け入れ基準

実装完了の判断基準：

- [ ] 基準1: 具体的な動作確認項目
- [ ] 基準2: 具体的な動作確認項目
- [ ] 基準3: エラーハンドリング確認
- [ ] 基準4: レスポンシブ対応確認
- [ ] 基準5: セキュリティ確認

---

## 🧪 テスト仕様

### TDD適用判断

- [ ] TDD適用: はい / いいえ
- **理由**: [TDD適用の理由、または不要な理由]

### テスト対象

| 対象 | ファイルパス | テストファイルパス |
|------|-------------|-------------------|
| Model | `app/models/xxx.rb` | `spec/models/xxx_spec.rb` |
| Service | `app/services/xxx_service.rb` | `spec/services/xxx_service_spec.rb` |
| Controller | `app/controllers/xxx_controller.rb` | `spec/controllers/xxx_controller_spec.rb` |

### Model: ModelName

#### describe 'メソッド名'

**正常系**:
- [ ] テストケース1: 説明
- [ ] テストケース2: 説明

**異常系**:
- [ ] テストケース1: 説明
- [ ] テストケース2: 説明

**エッジケース**:
- [ ] テストケース1: 説明
- [ ] テストケース2: 説明

### テストコード例

```ruby
RSpec.describe ModelName, type: :model do
  describe 'メソッド名' do
    context '正常系' do
      it 'テストケース1' do
        # Arrange（準備）
        model = create(:model_name, attribute: 'value')
        
        # Act（実行）
        result = model.method_name
        
        # Assert（検証）
        expect(result).to eq(expected_value)
      end
    end
    
    context '異常系' do
      it 'テストケース1' do
        # テストコード
      end
    end
    
    context 'エッジケース' do
      it 'テストケース1' do
        # テストコード
      end
    end
  end
end
```

### テストデータ（FactoryBot）

```ruby
# spec/factories/model_names.rb
FactoryBot.define do
  factory :model_name do
    attribute1 { 'value1' }
    attribute2 { 'value2' }
    
    trait :with_association do
      association :related_model
    end
    
    trait :special_case do
      attribute1 { 'special_value' }
    end
  end
end
```

### カバレッジ目標

- Model: 95%以上
- Service: 95%以上
- Controller: 90%以上

---

## 💡 実装メモ

### Claude Codeへの指示
- 実装時の注意点
- 使用すべきライブラリ・gem
- 参考にすべき既存実装

### 技術的制約
- Rails 8.1.1の制約
- PostgreSQL 17の制約
- パフォーマンス要件

### 参考資料
- 関連ドキュメントへのリンク
- 外部リソースへのリンク

---

## 📊 実装履歴

| 日付 | 担当 | 内容 |
|------|------|------|
| YYYY-MM-DD | Kiro | 初版作成 |
| YYYY-MM-DD | Claude Code | 実装完了 |
| YYYY-MM-DD | Kiro | 検証完了・仕様書更新 |

---

## 🔗 関連ドキュメント

- Phase計画書: `/docs/development/phase_plan_rails_8_1_1.md`
- 総合仕様書: `/docs/specifications/spec.md`
- データベース設計: `/docs/database/schema_design_v2.md`
