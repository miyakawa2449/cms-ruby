# Phase 7: セキュリティ・運用強化 - タスクリスト

## 📅 作成日: 2026-01-22
## 🎯 Phase: 7
## ⚡️ 優先度: 高
## 📊 ステータス: 未着手

---

## 📋 タスク概要

- **総タスク数**: 85タスク
- **完了**: 0タスク
- **進捗**: 0%
- **期間**: 2026-02-01 〜 2026-02-28（28日間）

---

## 🔐 Phase 7.1: 2段階認証（2FA）実装（5日間）

### 基盤実装（Day 1-2）

- [ ] 1.1 devise-two-factor, rqrcode gem追加
  - Gemfileに追加
  - bundle install実行
  - 動作確認

- [ ] 1.2 AdminUserモデル拡張（マイグレーション）
  - マイグレーションファイル作成
  - 2FA用カラム追加（encrypted_otp_secret等）
  - マイグレーション実行
  - モデルにdevise :two_factor_authenticatable追加

- [ ] 1.3 2FA設定画面UI実装
  - app/views/admin/two_factor_auth/new.html.erb作成
  - 有効化/無効化トグル実装
  - QRコード表示エリア実装
  - バックアップコード表示エリア実装

- [ ] 1.4 QRコード生成機能実装
  - app/services/two_factor_auth/qr_code_generator.rb作成
  - QRコード生成ロジック実装
  - Base64エンコード実装

### ログインフロー拡張（Day 3-4）

- [ ] 1.5 2FA認証コード入力画面実装
  - app/views/admin_users/sessions/two_factor.html.erb作成
  - 認証コード入力フォーム実装
  - バックアップコード入力オプション実装

- [ ] 1.6 バックアップコード機能実装
  - AdminUser#generate_otp_backup_codes!実装
  - AdminUser#validate_backup_code実装
  - バックアップコードダウンロード機能実装

- [ ] 1.7 デバイス信頼機能実装
  - AdminUser#trust_device!実装
  - AdminUser#device_trusted?実装
  - 「このデバイスを信頼する」チェックボックス実装
  - Cookie管理実装（30日間有効）

- [ ] 1.8 2FA無効化機能実装
  - 無効化フォーム実装
  - パスワード確認実装
  - OTPコード確認実装
  - メール通知実装

### テスト・ドキュメント（Day 5）

- [ ] 1.9 RSpecテスト実装（15件）
  - spec/models/admin_user_spec.rb（2FA関連）
  - spec/services/two_factor_auth/qr_code_generator_spec.rb
  - spec/controllers/admin/two_factor_auth_controller_spec.rb
  - spec/requests/admin/two_factor_auth_spec.rb

- [ ] 1.10 E2Eテスト実装（3件）
  - spec/system/admin/two_factor_auth_spec.rb
  - 2FA設定からログインまでの完全フロー
  - バックアップコード使用フロー
  - デバイス信頼フロー

- [ ] 1.11 ドキュメント作成
  - docs/features/two_factor_auth.md作成
  - 2FA設定手順書作成
  - トラブルシューティングガイド作成

---

## 🔗 Phase 7.2: 管理画面URL管理（5日間）

### URL変更機能（Day 1-2）

- [ ] 2.1 AdminPathHistoryモデル作成
  - マイグレーションファイル作成
  - モデルファイル作成
  - バリデーション実装
  - アソシエーション設定

- [ ] 2.2 AdminPath::Updaterサービス実装
  - app/services/admin_path/updater.rb作成
  - URL変更ロジック実装
  - 環境変数更新機能実装
  - バリデーション実装（予約語チェック等）

- [ ] 2.3 URL変更画面UI実装
  - app/views/admin/admin_path_settings/edit.html.erb作成
  - URL変更フォーム実装
  - プレビュー機能実装
  - 変更履歴表示実装

- [ ] 2.4 環境変数更新機能実装
  - .envファイル更新ロジック実装
  - ルーティング再読み込み実装
  - エラーハンドリング実装

### 自動ローテーション（Day 3-4）

- [ ] 2.5 AdminPath::RotationJob実装
  - app/jobs/admin_path/rotation_job.rb作成
  - ローテーションロジック実装
  - 通知ロジック実装（24時間前）
  - ランダムパス生成実装

- [ ] 2.6 Sidekiq-cronスケジュール設定
  - config/schedule.yml更新
  - 6時間ごとのチェック設定
  - 動作確認

- [ ] 2.7 ローテーション設定画面UI実装
  - app/views/admin/admin_path_settings/rotation.html.erb作成
  - ローテーション頻度選択実装
  - 次回ローテーション日時表示実装
  - ローテーション履歴表示実装

- [ ] 2.8 緊急ローテーション機能実装
  - 緊急ローテーションボタン実装
  - 確認ダイアログ実装
  - 即座にURL変更実装
  - 通知送信実装

### テスト・ドキュメント（Day 5）

- [ ] 2.9 RSpecテスト実装（15件）
  - spec/models/admin_path_history_spec.rb
  - spec/services/admin_path/updater_spec.rb
  - spec/jobs/admin_path/rotation_job_spec.rb
  - spec/controllers/admin/admin_path_settings_controller_spec.rb

- [ ] 2.10 E2Eテスト実装（2件）
  - spec/system/admin/admin_path_settings_spec.rb
  - URL変更からアクセスまでの完全フロー
  - 自動ローテーションフロー

- [ ] 2.11 ドキュメント作成
  - docs/features/admin_path_management.md作成
  - URL変更手順書作成
  - 自動ローテーション設定ガイド作成

---

## 💾 Phase 7.3: 自動バックアップシステム（5日間）

### バックアップ作成（Day 1-2）

- [ ] 3.1 BackupLogモデル作成
  - マイグレーションファイル作成
  - モデルファイル作成
  - バリデーション実装
  - enum設定（backup_type, status）

- [ ] 3.2 Backup::Creatorサービス実装
  - app/services/backup/creator.rb作成
  - データベースダンプ機能実装（pg_dump + gzip）
  - Active Storageコピー機能実装
  - 設定ファイルコピー機能実装
  - ZIP圧縮機能実装

- [ ] 3.3 Backup::S3Uploaderサービス実装
  - app/services/backup/s3_uploader.rb作成
  - S3アップロード機能実装
  - 暗号化設定（SSE-S3）
  - S3キー生成機能実装

- [ ] 3.4 Sidekiq-cronスケジュール設定
  - config/schedule.yml更新
  - 日次バックアップ設定（毎日午前3時）
  - 週次バックアップ設定（毎週日曜日午前3時）
  - 月次バックアップ設定（毎月1日午前3時）

### バックアップ復元（Day 3-4）

- [ ] 3.5 Backup::Restorerサービス実装
  - app/services/backup/restorer.rb作成
  - S3ダウンロード機能実装
  - ZIP解凍機能実装
  - データベース復元機能実装（pg_restore）
  - Active Storage復元機能実装

- [ ] 3.6 バックアップ一覧画面UI実装
  - app/views/admin/backups/index.html.erb作成
  - バックアップ一覧表示実装
  - フィルタ機能実装（backup_type, status）
  - ページネーション実装

- [ ] 3.7 復元機能UI実装
  - 復元ボタン実装
  - 確認ダイアログ実装
  - 復元進捗表示実装
  - 復元完了通知実装

- [ ] 3.8 手動バックアップ機能実装
  - 手動バックアップボタン実装
  - 即座にバックアップ実行実装
  - 進捗表示実装

### テスト・ドキュメント（Day 5）

- [ ] 3.9 RSpecテスト実装（20件）
  - spec/models/backup_log_spec.rb
  - spec/services/backup/creator_spec.rb
  - spec/services/backup/s3_uploader_spec.rb
  - spec/services/backup/restorer_spec.rb
  - spec/jobs/backup/create_job_spec.rb

- [ ] 3.10 E2Eテスト実装（3件）
  - spec/system/admin/backups_spec.rb
  - バックアップ作成から復元までの完全フロー
  - 手動バックアップフロー
  - 復元フロー

- [ ] 3.11 バックアップ・復元手順書作成
  - docs/operations/backup_restore_guide.md作成
  - 手動バックアップ手順
  - 復元手順
  - トラブルシューティング

- [ ] 3.12 災害復旧計画（DR Plan）作成
  - docs/operations/disaster_recovery_plan.md作成
  - 復旧手順
  - RTO/RPO定義
  - 連絡体制

---

## 🔍 Phase 7.4: セキュリティ監査自動化（5日間）

### 静的解析自動化（Day 1-2）

- [ ] 4.1 SecurityAuditLogモデル作成
  - マイグレーションファイル作成
  - モデルファイル作成
  - バリデーション実装
  - enum設定（audit_type, status）

- [ ] 4.2 Security::AuditJob実装
  - app/jobs/security/audit_job.rb作成
  - Brakeman実行ロジック実装
  - bundler-audit実行ロジック実装
  - 結果パース実装

- [ ] 4.3 Brakeman統合
  - Brakeman実行コマンド実装
  - JSON出力パース実装
  - 脆弱性カウント実装
  - レポート保存実装

- [ ] 4.4 bundler-audit統合
  - bundler-audit実行コマンド実装
  - JSON出力パース実装
  - 脆弱性カウント実装
  - レポート保存実装

### GitHub Actions統合（Day 3-4）

- [ ] 4.5 GitHub Actionsワークフロー作成
  - .github/workflows/security_audit.yml作成
  - 日次実行設定
  - Brakeman実行設定
  - bundler-audit実行設定

- [ ] 4.6 脆弱性アラート設定
  - GitHub Issues自動作成設定
  - メール通知設定
  - Slack通知設定（オプション）

- [ ] 4.7 週次レポート機能実装
  - 週次レポート生成ロジック実装
  - メール送信実装
  - レポートフォーマット実装

### テスト・ドキュメント（Day 5）

- [ ] 4.8 RSpecテスト実装（10件）
  - spec/models/security_audit_log_spec.rb
  - spec/jobs/security/audit_job_spec.rb
  - spec/services/security/brakeman_runner_spec.rb
  - spec/services/security/bundler_audit_runner_spec.rb

- [ ] 4.9 ドキュメント作成
  - docs/security/security_audit_guide.md作成
  - セキュリティ監査手順
  - 脆弱性対応フロー
  - レポート読み方ガイド

---

## 📊 Phase 7.5: 監視機能強化（5日間）

### ヘルスチェック（Day 1-2）

- [ ] 5.1 HealthCheckLogモデル作成
  - マイグレーションファイル作成
  - モデルファイル作成
  - バリデーション実装
  - enum設定（check_type, status）

- [ ] 5.2 HealthController実装
  - app/controllers/health_controller.rb作成
  - /healthエンドポイント実装
  - JSON形式レスポンス実装

- [ ] 5.3 データベース接続チェック実装
  - check_databaseメソッド実装
  - SELECT 1クエリ実行
  - エラーハンドリング実装

- [ ] 5.4 Redis接続チェック実装
  - check_redisメソッド実装
  - Redis.current.ping実行
  - エラーハンドリング実装

- [ ] 5.5 ディスク容量チェック実装
  - check_diskメソッド実装
  - Sys::Filesystem使用
  - 使用率計算実装
  - 閾値判定実装（75%, 90%）

- [ ] 5.6 メモリ使用量チェック実装
  - check_memoryメソッド実装
  - free -mコマンド実行
  - 使用率計算実装
  - 閾値判定実装（75%, 90%）

### 監視ダッシュボード（Day 3-4）

- [ ] 5.7 Admin::MonitoringController実装
  - app/controllers/admin/monitoring_controller.rb作成
  - dashboardアクション実装
  - メトリクス取得ロジック実装

- [ ] 5.8 ダッシュボードUI実装
  - app/views/admin/monitoring/dashboard.html.erb作成
  - ヘルスステータス表示実装
  - メトリクス表示実装
  - 最近のバックアップ表示実装
  - 最近のセキュリティ監査表示実装

- [ ] 5.9 メトリクス表示（Chart.js）実装
  - Chart.js統合
  - ディスク使用率グラフ実装
  - メモリ使用率グラフ実装
  - バックアップ履歴グラフ実装

- [ ] 5.10 アラート機能実装
  - 異常検知ロジック実装
  - メール通知実装
  - Slack通知実装（オプション）

### テスト・ドキュメント（Day 5）

- [ ] 5.11 RSpecテスト実装（15件）
  - spec/models/health_check_log_spec.rb
  - spec/controllers/health_controller_spec.rb
  - spec/controllers/admin/monitoring_controller_spec.rb
  - spec/requests/health_spec.rb

- [ ] 5.12 E2Eテスト実装（2件）
  - spec/system/admin/monitoring_spec.rb
  - ヘルスチェックフロー
  - ダッシュボード表示フロー

- [ ] 5.13 ドキュメント作成
  - docs/operations/monitoring_guide.md作成
  - 監視項目説明
  - アラート対応手順
  - トラブルシューティング

---

---

## 📧 Phase 7.8: 通知機能実装（2日間）

### Slack通知拡張（Day 1）

- [ ] 8.1 SlackNotifierサービス拡張
  - app/services/slack_notifier.rb更新
  - notify_2fa_changedメソッド実装
  - notify_admin_path_changedメソッド実装
  - notify_backup_statusメソッド実装
  - notify_security_issueメソッド実装
  - notify_health_check_alertメソッド実装

- [ ] 8.2 環境変数設定
  - .envにADMIN_EMAIL追加
  - .envにSECURITY_AUDIT_EMAIL追加
  - SLACK_WEBHOOK_URL確認

### メール通知実装（Day 2）

- [ ] 8.3 AdminPathMailer実装
  - app/mailers/admin_path_mailer.rb作成
  - path_changedメソッド実装
  - rotation_notificationメソッド実装
  - メールテンプレート作成

- [ ] 8.4 BackupMailer実装
  - app/mailers/backup_mailer.rb作成
  - backup_successメソッド実装
  - backup_failedメソッド実装
  - restore_successメソッド実装
  - restore_failedメソッド実装
  - メールテンプレート作成

- [ ] 8.5 SecurityMailer実装
  - app/mailers/security_mailer.rb作成
  - brakeman_issuesメソッド実装
  - bundler_audit_issuesメソッド実装
  - weekly_reportメソッド実装
  - メールテンプレート作成

- [ ] 8.6 TwoFactorAuthMailer実装
  - app/mailers/two_factor_auth_mailer.rb作成
  - enabledメソッド実装
  - disabledメソッド実装
  - メールテンプレート作成

- [ ] 8.7 通知機能テスト実装（10件）
  - spec/services/slack_notifier_spec.rb更新
  - spec/mailers/admin_path_mailer_spec.rb
  - spec/mailers/backup_mailer_spec.rb
  - spec/mailers/security_mailer_spec.rb
  - spec/mailers/two_factor_auth_mailer_spec.rb

---

## 🏗 Phase 7.9: 構造化データ拡張（3日間）

### Schema実装（Day 1-2）

- [ ] 9.1 FAQ Schema実装
  - app/helpers/structured_data_helper.rb拡張
  - FAQ Schemaマークアップ実装
  - よくある質問ページに適用

- [ ] 9.2 HowTo Schema実装
  - HowTo Schemaマークアップ実装
  - チュートリアル記事に適用

- [ ] 9.3 BreadcrumbList改善
  - 全ページにBreadcrumbList実装
  - 階層構造の明確化

- [ ] 9.4 Organization Schema実装
  - Organization Schemaマークアップ実装
  - サイト全体に適用

### テスト・検証（Day 3）

- [ ] 9.5 RSpecテスト実装（5件）
  - spec/helpers/structured_data_helper_spec.rb
  - FAQ Schema生成テスト
  - HowTo Schema生成テスト
  - BreadcrumbList生成テスト
  - Organization Schema生成テスト

- [ ] 9.6 Google Rich Results Test検証
  - 全ページでRich Results Test実行
  - エラー修正
  - 検証結果ドキュメント化

- [ ] 9.7 ドキュメント作成
  - docs/seo/structured_data_guide.md作成
  - 構造化データ説明
  - 実装方法
  - 検証方法

---

## 🧪 Phase 7.10: 統合テスト・最終確認（3日間）

### 統合テスト（Day 1-2）

- [ ] 10.1 全機能統合テスト実施
  - 2FA機能テスト
  - URL管理機能テスト
  - バックアップ機能テスト
  - セキュリティ監査機能テスト
  - 監視機能テスト
  - 通知機能テスト

- [ ] 10.2 パフォーマンステスト実施
  - バックアップ実行時間測定
  - 復元時間測定
  - ヘルスチェックレスポンスタイム測定

- [ ] 10.3 セキュリティテスト実施
  - 2FA突破テスト
  - URL推測テスト
  - バックアップ暗号化確認

### 最終確認（Day 3）

- [ ] 10.4 ドキュメント最終確認
  - すべてのドキュメントレビュー
  - 不足情報追加
  - 誤字脱字修正

- [ ] 10.5 本番環境設定確認
  - 環境変数設定確認
  - AWS S3設定確認
  - IAMロール設定確認
  - Sidekiq-cron設定確認

- [ ] 10.6 デプロイ準備
  - デプロイスクリプト確認
  - ロールバック手順確認
  - 本番環境テスト計画作成

---

## 📊 進捗管理

### タスク完了チェックリスト

#### Phase 7.1: 2段階認証（11タスク）
- 完了: 0/11
- 進捗: 0%

#### Phase 7.2: 管理画面URL管理（11タスク）
- 完了: 0/11
- 進捗: 0%

#### Phase 7.3: 自動バックアップシステム（12タスク）
- 完了: 0/12
- 進捗: 0%

#### Phase 7.4: セキュリティ監査自動化（9タスク）
- 完了: 0/9
- 進捗: 0%

#### Phase 7.5: 監視機能強化（13タスク）
- 完了: 0/13
- 進捗: 0%

#### Phase 7.8: 通知機能実装（7タスク）
- 完了: 0/7
- 進捗: 0%

#### Phase 7.9: 構造化データ拡張（7タスク）
- 完了: 0/7
- 進捗: 0%

#### Phase 7.10: 統合テスト・最終確認（6タスク）
- 完了: 0/6
- 進捗: 0%

### 総合進捗
- **総タスク数**: 76タスク
- **完了タスク**: 0タスク
- **進捗率**: 0%

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-01-22  
**🔄 バージョン**: v1.0  
**📋 ステータス**: 未着手  
**🎯 開始予定日**: 2026-02-01  
**🏁 完了予定日**: 2026-02-28
