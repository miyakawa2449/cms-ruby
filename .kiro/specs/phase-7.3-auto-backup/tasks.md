# Phase 7.3: 自動バックアップシステム - 実装計画

## 📋 概要

Phase 7.3では、PostgreSQLデータベース、Active Storage、設定ファイルを自動的にバックアップし、AWS S3に暗号化して保存するシステムを実装します。設計書に基づいて、段階的に機能を実装し、各ステップでテストを実施します。

---

## 📝 タスク

- [ ] 1. 環境セットアップとGem追加
  - aws-sdk-s3 gemをGemfileに追加
  - bundle installを実行
  - 環境変数テンプレートを.env.sampleに追加（AWS_ACCESS_KEY_ID、AWS_SECRET_ACCESS_KEY、AWS_REGION、S3_BACKUP_BUCKET）
  - _Requirements: 4.1_

- [ ] 2. BackupLogモデルとマイグレーション作成
  - [ ] 2.1 BackupLogモデルを作成
    - backup_type（enum: daily, weekly, monthly, restore）
    - status（enum: in_progress, success, failed）
    - started_at、completed_at、file_size、error_message、s3_keys（array）
    - バリデーション、スコープ、インスタンスメソッド（duration、file_size_mb）を実装
    - _Requirements: 1.6, 1.7, 5.5, 9.6_
  
  - [ ]* 2.2 BackupLogモデルのテストを作成
    - バリデーションテスト
    - スコープテスト
    - インスタンスメソッドテスト
    - _Requirements: 1.6, 1.7, 5.5, 9.6_

- [ ] 3. DatabaseBackupServiceを実装
  - [ ] 3.1 DatabaseBackupServiceクラスを作成
    - pg_dumpコマンドでPostgreSQL全テーブルをダンプ（-Fc形式）
    - gzipで圧縮
    - チェックサム（SHA256）を計算
    - 一時ファイルをtmp/backupディレクトリに保存
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.7_
  
  - [ ]* 3.2 DatabaseBackupServiceのプロパティテストを作成
    - **Property 1: データベース完全性**
    - **Property 2: バックアップファイル形式**（database部分）
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**
  
  - [ ]* 3.3 DatabaseBackupServiceのユニットテストを作成
    - pg_dump実行の成功ケース
    - 圧縮処理の検証
    - チェックサム計算の検証
    - データベース接続エラーのハンドリング
    - _Requirements: 1.8_

- [ ] 4. StorageBackupServiceを実装
  - [ ] 4.1 StorageBackupServiceクラスを作成
    - storage/ディレクトリをtar.gz形式でアーカイブ
    - チェックサム（SHA256）を計算
    - storage/ディレクトリが存在しない場合は警告ログを記録し、空のアーカイブを作成
    - _Requirements: 2.1, 2.2, 2.4_
  
  - [ ]* 4.2 StorageBackupServiceのプロパティテストを作成
    - **Property 2: バックアップファイル形式**（storage部分）
    - **Validates: Requirements 2.1, 2.2**
  
  - [ ]* 4.3 StorageBackupServiceのユニットテストを作成
    - tar.gz作成の成功ケース
    - 空ディレクトリ処理のエッジケース
    - チェックサム計算の検証
    - _Requirements: 2.4_

- [ ] 5. ConfigBackupServiceを実装
  - [ ] 5.1 ConfigBackupServiceクラスを作成
    - 必須ファイル（.env、config/credentials.yml.enc）の存在確認
    - オプションファイル（.env.production、config/master.key）を含める
    - tar.gz形式でアーカイブ
    - チェックサム（SHA256）を計算
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_
  
  - [ ]* 5.2 ConfigBackupServiceのプロパティテストを作成
    - **Property 2: バックアップファイル形式**（config部分）
    - **Property 4: 設定ファイル完全性**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**
  
  - [ ]* 5.3 ConfigBackupServiceのユニットテストを作成
    - 必須ファイル検証
    - オプションファイル処理
    - アーカイブ作成
    - 必須ファイル欠落エラーのハンドリング
    - _Requirements: 3.7, 3.8_

- [ ] 6. Checkpoint - バックアップサービスの動作確認
  - 全てのテストが成功することを確認
  - 質問があれば確認

- [ ] 7. S3Serviceを実装
  - [ ] 7.1 S3Serviceクラスを作成
    - Aws::S3::Clientを初期化（環境変数から認証情報を取得）
    - uploadメソッド: S3にファイルをアップロード（SSE-S3暗号化、メタデータ付き）
    - list_backupsメソッド: S3からバックアップリストを取得
    - downloadメソッド: S3からファイルをダウンロード
    - deleteメソッド: S3からファイルを削除
    - get_latest_backup_sizeメソッド: 最新バックアップのサイズを取得
    - _Requirements: 4.1, 4.2, 4.3, 8.1_
  
  - [ ]* 7.2 S3Serviceのプロパティテストを作成
    - **Property 5: S3暗号化アップロード**
    - **Property 6: 一時ファイルクリーンアップ**
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**
  
  - [ ]* 7.3 S3Serviceのユニットテストを作成
    - アップロード成功ケース
    - ダウンロード成功ケース
    - リスト取得成功ケース
    - 削除成功ケース
    - S3エラーのハンドリング
    - _Requirements: 8.5_

- [ ] 8. S3RetentionManagerを実装
  - [ ] 8.1 S3RetentionManagerクラスを作成
    - 保持期間の定義（daily: 7日、weekly: 28日、monthly: 365日）
    - cleanupメソッド: 保持期間を超えた古いバックアップを削除
    - 削除ログを記録
    - 削除エラーは警告ログを記録するが、処理は継続
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [ ]* 8.2 S3RetentionManagerのプロパティテストを作成
    - **Property 8: バックアップ保持期間**
    - **Property 9: 世代管理エラー耐性**
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**
  
  - [ ]* 8.3 S3RetentionManagerのユニットテストを作成
    - 世代管理の成功ケース
    - 削除処理のエラーハンドリング
    - ログ記録の検証
    - _Requirements: 6.4, 6.5_

- [ ] 9. BackupServiceを実装
  - [ ] 9.1 BackupServiceクラスを作成
    - executeメソッド: バックアップ処理のオーケストレーション
    - DatabaseBackupService、StorageBackupService、ConfigBackupServiceを呼び出し
    - S3Serviceでアップロード
    - S3RetentionManagerで世代管理
    - BackupMailerとSlackNotifierで通知
    - エラーハンドリングとリトライロジック（最大3回）
    - 一時ファイルのクリーンアップ
    - _Requirements: 4.4, 4.5, 4.6, 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ]* 9.2 BackupServiceのプロパティテストを作成
    - **Property 3: バックアップメタデータ記録**
    - **Property 7: S3アップロードリトライ**
    - **Property 10: バックアップ成功通知**
    - **Property 11: バックアップ失敗通知**
    - **Property 12: 通知エラー耐性**
    - **Property 20: データベース接続エラー**
    - **Property 21: 必須設定ファイル欠落エラー**
    - **Validates: Requirements 1.6, 1.7, 4.4, 4.5, 4.6, 7.1, 7.2, 7.3, 7.4, 7.5, 1.8, 3.7**
  
  - [ ]* 9.3 BackupServiceのユニットテストを作成
    - バックアップ実行の成功ケース
    - エラーハンドリング
    - リトライロジック
    - 通知送信
    - 一時ファイルクリーンアップ
    - _Requirements: 4.4, 4.5, 4.6, 7.5_

- [ ] 10. Checkpoint - バックアップ処理の統合確認
  - 全てのテストが成功することを確認
  - 質問があれば確認

- [ ] 11. バックアップジョブを実装
  - [ ] 11.1 Backup::DailyBackupJobを作成
    - BackupService.new(backup_type: "daily").executeを呼び出し
    - queue_as :backup
    - _Requirements: 5.4_
  
  - [ ] 11.2 Backup::WeeklyBackupJobを作成
    - BackupService.new(backup_type: "weekly").executeを呼び出し
    - queue_as :backup
    - _Requirements: 5.4_
  
  - [ ] 11.3 Backup::MonthlyBackupJobを作成
    - BackupService.new(backup_type: "monthly").executeを呼び出し
    - queue_as :backup
    - _Requirements: 5.4_
  
  - [ ]* 11.4 バックアップジョブのテストを作成
    - 各ジョブがBackupServiceを呼び出すことを検証
    - Sidekiqキューに追加されることを検証
    - _Requirements: 5.4_

- [ ] 12. Sidekiq-cronスケジューラーを設定
  - [ ] 12.1 config/initializers/sidekiq_cron.rbを更新
    - daily_backup: 毎日午前3時（JST）
    - weekly_backup: 毎週日曜日午前3時（JST）
    - monthly_backup: 毎月1日午前3時（JST）
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 13. RestoreServiceを実装
  - [ ] 13.1 DatabaseRestoreServiceを作成
    - pg_restoreコマンドでデータベースを復元
    - _Requirements: 9.3_
  
  - [ ] 13.2 StorageRestoreServiceを作成
    - tar.gzを展開してstorage/ディレクトリに復元
    - _Requirements: 9.4_
  
  - [ ] 13.3 ConfigRestoreServiceを作成
    - tar.gzを展開して設定ファイルを復元
    - _Requirements: 9.5_
  
  - [ ] 13.4 RestoreServiceクラスを作成
    - executeメソッド: 復元処理のオーケストレーション
    - S3からバックアップファイルをダウンロード
    - DatabaseRestoreService、StorageRestoreService、ConfigRestoreServiceを呼び出し
    - BackupLogに復元ログを記録
    - BackupMailerで通知
    - エラーハンドリング
    - 一時ファイルのクリーンアップ
    - _Requirements: 9.2, 9.6, 9.7, 9.8_
  
  - [ ]* 13.5 RestoreServiceのプロパティテストを作成
    - **Property 13: データベース復元ラウンドトリップ**
    - **Property 14: Active Storage復元ラウンドトリップ**
    - **Property 15: 設定ファイル復元ラウンドトリップ**
    - **Property 16: 復元ログ記録**
    - **Validates: Requirements 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8**
  
  - [ ]* 13.6 RestoreServiceのユニットテストを作成
    - 復元処理の成功ケース
    - エラーハンドリング
    - ログ記録
    - 通知送信
    - 一時ファイルクリーンアップ
    - _Requirements: 9.8_

- [ ] 14. Restore::RestoreJobを実装
  - [ ] 14.1 Restore::RestoreJobを作成
    - RestoreService.new(backup_keys: backup_keys).executeを呼び出し
    - queue_as :backup
    - _Requirements: 9.9_
  
  - [ ]* 14.2 Restore::RestoreJobのプロパティテストを作成
    - **Property 17: 復元バックグラウンド実行**
    - **Validates: Requirements 9.9**

- [ ] 15. Checkpoint - 復元機能の動作確認
  - 全てのテストが成功することを確認
  - 質問があれば確認

- [ ] 16. 管理画面にバックアップ一覧ページを追加
  - [ ] 16.1 Admin::BackupsControllerを作成
    - indexアクション: S3からバックアップリストを取得、日時降順でソート
    - フィルタリング機能（バックアップタイプ）
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  
  - [ ] 16.2 app/views/admin/backups/index.html.erbを作成
    - バックアップ一覧テーブル（日時、タイプ、ファイルサイズ）
    - フィルタリングフォーム
    - 復元ボタン
    - _Requirements: 8.2, 8.3, 8.4_
  
  - [ ]* 16.3 Admin::BackupsControllerのテストを作成
    - indexアクションのテスト
    - フィルタリング機能のテスト
    - S3エラーハンドリングのテスト
    - _Requirements: 8.5_
  
  - [ ]* 16.4 バックアップ一覧のプロパティテストを作成
    - **Property 18: バックアップ一覧ソート**
    - **Property 19: バックアップフィルタリング**
    - **Property 22: S3リスト取得エラー**
    - **Validates: Requirements 8.2, 8.3, 8.4, 8.5**

- [ ] 17. 管理画面に復元機能を追加
  - [ ] 17.1 Admin::BackupsController#restoreアクションを追加
    - 確認ダイアログ表示
    - Restore::RestoreJobをエンキュー
    - _Requirements: 9.1, 9.2_
  
  - [ ] 17.2 app/views/admin/backups/_restore_modal.html.erbを作成
    - 確認ダイアログ
    - 復元対象の情報表示
    - _Requirements: 9.1_
  
  - [ ]* 17.3 復元機能のテストを作成
    - restoreアクションのテスト
    - ジョブエンキューの検証
    - _Requirements: 9.1, 9.2_

- [ ] 18. ルーティングを追加
  - [ ] 18.1 config/routes.rbを更新
    - namespace :admin do resources :backups, only: [:index] do post :restore, on: :member end end
    - _Requirements: 8.1, 9.1_

- [ ] 19. 統合テストを実施
  - [ ]* 19.1 バックアップ→S3アップロード→世代管理の統合テスト
    - エンドツーエンドのフロー検証
    - _Requirements: 1.1-7.5_
  
  - [ ]* 19.2 バックアップ→復元のラウンドトリップ統合テスト
    - データベース、Storage、設定ファイルの完全なラウンドトリップ
    - _Requirements: 9.1-9.9_

- [ ] 20. Checkpoint - 全機能の動作確認
  - 全てのテストが成功することを確認
  - テストカバレッジが85%以上であることを確認
  - 質問があれば確認

- [ ] 21. ドキュメント作成
  - [ ] 21.1 docs/backup_restore_guide.mdを作成
    - バックアップ・復元手順書
    - トラブルシューティングガイド
    - 災害復旧計画（DR Plan）
    - _Requirements: 10.1-13.5_
  
  - [ ] 21.2 docs/aws_s3_setup_guide.mdを作成
    - AWS S3セットアップガイド（設計書から転記）
    - IAM認証情報作成ガイド（設計書から転記）
    - コスト見積もり（設計書から転記）
    - _Requirements: 10.1-13.5_

---

## 📊 タスクサマリー

- **合計タスク数**: 21
- **サブタスク数**: 47
- **テストタスク数**: 22（オプション）
- **チェックポイント数**: 4

---

## 📝 注意事項

1. **テストタスク**: `*`マークのタスクはオプションですが、実装を推奨します
2. **チェックポイント**: 各チェックポイントで動作確認を行い、問題があれば修正します
3. **環境変数**: AWS認証情報は`.env`ファイルに設定し、`.gitignore`に含めます
4. **S3バケット**: 実装前にAWS S3バケットを作成し、IAMユーザーを設定します
5. **Phase 7.8依存**: BackupMailerとSlackNotifierはPhase 7.8で実装済みです

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-01-23  
**🔄 バージョン**: v1.0  
**📋 ステータス**: 実装計画完成
