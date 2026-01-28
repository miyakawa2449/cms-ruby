# Phase 7.2: 管理画面URL管理 - タスクリスト

## 📅 作成日: 2026-01-23
## 🎯 Phase: 7.2
## ⚡️ 優先度: 高
## 📊 ステータス: 未着手

---

## 📋 タスク概要

- **総タスク数**: 11タスク
- **完了**: 0タスク
- **進捗**: 0%
- **期間**: 2026-01-23 〜 2026-01-28（5日間）

---

## 🔗 Phase 7.2: 管理画面URL管理（5日間）

### URL変更機能（Day 1-2）

- [ ] 2.1 AdminPathHistoryモデル作成
  - マイグレーションファイル作成
  - モデルファイル作成
  - バリデーション実装
  - アソシエーション設定
  - enum設定（change_type）
  - scope設定（recent, by_type）

- [ ] 2.2 AdminPath::Updaterサービス実装
  - app/services/admin_path/updater.rb作成
  - URL変更ロジック実装
  - 環境変数更新機能実装
  - バリデーション実装（予約語チェック等）
  - 履歴記録機能実装
  - ルーティング再読み込み実装
  - 通知送信実装

- [ ] 2.3 URL変更画面UI実装
  - app/views/admin/admin_path_settings/edit.html.erb作成
  - 現在のURL表示実装
  - URL変更フォーム実装
  - 変更理由入力欄実装
  - 変更履歴表示実装
  - Turbo無効化設定
  - 確認ダイアログ実装

- [ ] 2.4 環境変数更新機能実装
  - .envファイル更新ロジック実装
  - ルーティング再読み込み実装
  - エラーハンドリング実装

### 自動ローテーション（Day 3-4）

- [ ] 2.5 AdminPath::RotationJob実装
  - app/jobs/admin_path/rotation_job.rb作成
  - ローテーションロジック実装
  - ローテーション判定実装
  - ランダムパス生成実装
  - 通知ロジック実装

- [ ] 2.6 Sidekiq-cronスケジュール設定
  - config/schedule.yml作成または更新
  - 6時間ごとのチェック設定
  - 動作確認

- [ ] 2.7 ローテーション設定画面UI実装
  - 自動ローテーション設定表示実装
  - ローテーション頻度表示実装
  - 次回ローテーション日時表示実装
  - ローテーション履歴表示実装

- [ ] 2.8 緊急ローテーション機能実装
  - 緊急ローテーションボタン実装
  - 確認ダイアログ実装
  - ランダムURL生成実装
  - 即座にURL変更実装
  - 通知送信実装

### テスト・ドキュメント（Day 5）

- [ ] 2.9 RSpecテスト実装（15件）
  - spec/models/admin_path_history_spec.rb（5件）
  - spec/services/admin_path/updater_spec.rb（5件）
  - spec/jobs/admin_path/rotation_job_spec.rb（5件）

- [ ] 2.10 E2Eテスト実装（2件）※オプション
  - spec/system/admin/admin_path_settings_spec.rb
  - URL変更からアクセスまでの完全フロー
  - 自動ローテーションフロー

- [ ] 2.11 ドキュメント作成 ※オプション
  - docs/features/admin_path_management.md作成
  - URL変更手順書作成
  - 自動ローテーション設定ガイド作成

---

## 📊 進捗管理

### タスク完了チェックリスト

#### URL変更機能（4タスク）
- 完了: 0/4
- 進捗: 0%

#### 自動ローテーション（4タスク）
- 完了: 0/4
- 進捗: 0%

#### テスト・ドキュメント（3タスク）
- 完了: 0/3
- 進捗: 0%

### 総合進捗
- **総タスク数**: 11タスク
- **完了タスク**: 0タスク
- **進捗率**: 0%

---

## 🔗 依存関係

### Phase 7.8（通知機能）との統合
- AdminPathMailer#path_changed - URL変更通知
- AdminPathMailer#rotation_notification - 自動ローテーション通知
- SlackNotifier#notify_admin_path_changed - Slack通知

**これらは既に実装済みなので、呼び出すだけでOKです。**

---

## 📝 実装メモ

### 環境変数設定
```bash
# .env.production
ADMIN_PATH=admin-secure-panel-miyakawa2449
ADMIN_PATH_ROTATION_ENABLED=true
ADMIN_PATH_ROTATION_FREQUENCY=monthly  # weekly, monthly, quarterly
```

### ルーティング設定
```ruby
# config/routes.rb
admin_path = ENV.fetch('ADMIN_PATH', 'admin')

namespace :admin, path: admin_path do
  # 既存のルーティング...
  
  # 管理画面URL管理
  resource :admin_path_settings, only: [:edit, :update] do
    post :emergency_rotation, on: :collection
  end
end
```

### Sidekiq-cronスケジュール
```yaml
# config/schedule.yml
admin_path_rotation:
  cron: "0 */6 * * *"
  class: "AdminPath::RotationJob"
  queue: default
  description: "管理画面URL自動ローテーション"
```

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-01-23  
**🎯 Phase**: 7.2 管理画面URL管理  
**📋 ステータス**: 未着手  
**🚀 開始予定日**: 2026-01-23  
**🏁 完了予定日**: 2026-01-28
