# 明日のシンプルテスト計画

## 🎯 目的
**根本的な動作確認**: 最小構成でのRails Web動作テスト  
**問題特定**: 具体的にどこで問題が発生するかを段階的に特定

---

## 📋 実行手順

### 1. テストテーブル作成
```bash
# マイグレーション生成
docker-compose run --rm web rails generate migration CreateTestItems name:string description:text

# マイグレーション実行  
docker-compose run --rm web rails db:migrate
```

### 2. テストモデル作成
**ファイル**: `app/models/test_item.rb`
```ruby
class TestItem < ApplicationRecord
  validates :name, presence: true
end
```

### 3. テストコントローラー作成
**ファイル**: `app/controllers/test_controller.rb`
```ruby
class TestController < ApplicationController
  def index
    begin
      @test_items = TestItem.all
      
      response_text = [
        "✅ Rails Web Request SUCCESS!",
        "📊 Database Connection: OK", 
        "🗃️ Test Items Count: #{@test_items.count}",
        "📝 Items: #{@test_items.map(&:name).join(', ')}"
      ].join("\n")
      
      render plain: response_text
    rescue => e
      error_text = [
        "❌ Error occurred:",
        "🔍 Class: #{e.class}",
        "💬 Message: #{e.message}",
        "📍 Backtrace: #{e.backtrace&.first}"
      ].join("\n")
      
      render plain: error_text
    end
  end
end
```

### 4. ルート設定
**ファイル**: `config/routes.rb`
```ruby
# 既存ルートに追加
get "test", to: "test#index"
```

### 5. テストデータ投入
```bash
# Rails console
docker-compose run --rm web rails runner "
  TestItem.create!(name: 'Sample Item 1', description: 'Test data for debugging')
  TestItem.create!(name: 'Sample Item 2', description: 'Another test data')
  puts 'Test data created successfully!'
"
```

### 6. テスト実行
```bash
# Web request test
curl http://localhost:3000/test

# Expected success output:
# ✅ Rails Web Request SUCCESS!
# 📊 Database Connection: OK
# 🗃️ Test Items Count: 2  
# 📝 Items: Sample Item 1, Sample Item 2
```

---

## 🔍 段階的デバッグ

### Level 1: 最小テスト
- TestItemモデルなし
- 固定文字列のみ表示
- DB接続なし

### Level 2: DB接続テスト  
- `ActiveRecord::Base.connection.execute("SELECT 1")`
- DB接続可否のみ確認

### Level 3: モデルテスト
- TestItemモデル使用
- `TestItem.count`でレコード数確認

### Level 4: 完全テスト
- 全データ取得・表示
- エラーハンドリング付き

---

## 📁 準備済みファイル

### 今日の作業で作成済み
- `/reports/2025-12-12/4th.md` - 完全テストレポート
- `/config/initializers/` - 各種最適化設定
- `/config/puma_minimal.rb` - 最小構成設定

### 明日作成予定
- `db/migrate/*_create_test_items.rb`
- `app/models/test_item.rb` 
- `app/controllers/test_controller.rb`
- ルート追加

---

## 💭 予想される結果

### ✅ 成功パターン
**仮説**: 設定の問題であり、シンプルなテストは成功する
- レスポンス正常表示
- DB値取得成功
- 段階的に複雑な機能を追加して問題箇所を特定

### ❌ 失敗パターン  
**仮説**: Rails 8.0.4固有の問題であり、シンプルテストでも失敗
- 同様の500エラー発生
- より根本的な解決が必要（設定変更・バージョン調整等）

---

**🚀 明日のセッション**: 「session-start」と入力後、このファイルを参照してシンプルテストから開始してください。