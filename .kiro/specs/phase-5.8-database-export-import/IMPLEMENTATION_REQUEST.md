# データベースエクスポート/インポート機能 実装依頼

## 概要

管理画面からボタン操作でデータベースとActive Storageをエクスポート/インポートする機能を実装してください。

## 仕様ドキュメント

以下の3つのファイルを必ず確認してください：

- `requirements.md` - 要件定義（全8要件）
- `design.md` - 設計書（アーキテクチャ、コンポーネント、データモデル）
- `tasks.md` - 実装タスク（11タスク、段階的に実装）

## 実装方針

### 1. 段階的な実装

`tasks.md` の順序に従って、**1タスクずつ**実装してください：

1. Task 1: Setup and Infrastructure
2. Task 2: Implement Export Services
3. Task 3: Implement Export Controller Action
4. **Checkpoint**: Task 4 でテスト確認
5. Task 5: Implement Import Services
6. Task 6: Implement Import Controller Actions
7. **Checkpoint**: Task 7 でテスト確認
8. Task 8: Add UI Components
9. Task 9: Implement Security and Access Control
10. Task 10: Final Integration and Documentation
11. **Final Checkpoint**: Task 11 で全テスト確認

### 2. 各タスク完了時の報告

各タスクが完了したら、以下を報告してください：

- ✅ 実装した内容
- 📝 作成/変更したファイル
- ⚠️ 気になる点や確認事項（あれば）

報告後、次のタスクに進む前に **Kiro の承認を待ってください**。

### 3. テストについて

- **プロパティテスト**（`*`マーク付き）: 後回しでOK（MVP優先）
- **ユニットテスト**: 各サービスクラスに必須
- **統合テスト**: コントローラアクションに必須
- **チェックポイント**: Task 4, 7, 11 で必ずテストを実行

### 4. エラー発生時の対応

- **テスト失敗**: Codex に調査を依頼
- **仕様が不明確**: Kiro に質問
- **設計変更が必要**: ユーザーに確認を求める

## 重要な注意事項

### データの安全性

- インポート時は **トランザクション** で全処理を実行
- エラー時は **ロールバック** して元の状態を保つ
- 既存データ削除前に **確認ダイアログ** を表示（本番環境）

### セキュリティ

- エクスポート/インポートは **管理者のみ** アクセス可能
- AdminUser のパスワードは **必ずリセット**（開発環境用）
- 全操作を **ログに記録**

### パフォーマンス

- 大量データは **バッチ処理**
- 進捗を **ログに出力**
- 一時ファイルは **必ずクリーンアップ**

## 最初のタスク: Task 1 - Setup and Infrastructure

まず、以下から始めてください：

### 1.1 必要な gem の追加

`Gemfile` に `rubyzip` を追加：

```ruby
gem 'rubyzip'
```

### 1.2 ルーティングの追加

`config/routes.rb` に管理画面用のルートを追加：

```ruby
namespace :admin do
  resource :database, only: [] do
    collection do
      get :export
      get :import_form
      post :import
    end
  end
end
```

### 1.3 コントローラの作成

`app/controllers/admin/database_controller.rb` を作成：

```ruby
class Admin::DatabaseController < Admin::BaseController
  # TODO: 後のタスクで実装
  def export
    # Task 3 で実装
  end

  def import_form
    # Task 6 で実装
  end

  def import
    # Task 6 で実装
  end
end
```

### 1.4 サービスディレクトリの準備

以下のディレクトリを作成：

```
app/services/database_export/
app/services/database_import/
```

---

## 開始してください

Task 1 の実装を開始してください。完了したら報告をお願いします。

質問があれば、いつでも Kiro に確認してください。

---

**実装担当**: Claude Code  
**仕様管理**: Kiro  
**デバッグ**: Codex  
**最終判断**: ユーザー
