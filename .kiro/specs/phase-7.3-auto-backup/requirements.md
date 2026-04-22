# Phase 7.3: 自動バックアップシステム - 要件定義書

## 📅 作成日: 2026-01-23
## 🎯 Phase: 7.3
## ⚡️ 優先度: 高
## 📊 ステータス: 要件定義中

---

## 📋 目次

1. [概要](#概要)
2. [用語集](#用語集)
3. [要件](#要件)

---

## 🎯 概要

Phase 7.3では、PostgreSQLデータベース、Active Storage、設定ファイルを自動的にバックアップし、AWS S3に暗号化して保存するシステムを実装します。日次・週次・月次のスケジュールでバックアップを実行し、世代管理により適切な保存期間を維持します。また、管理画面からワンクリックで復元できる機能を提供します。

### 主要機能
- PostgreSQL全テーブルの自動バックアップ
- Active Storage（画像ファイル）の自動バックアップ
- 設定ファイルの自動バックアップ
- AWS S3への暗号化保存
- 世代管理（日次7日、週次4週、月次12ヶ月）
- 管理画面からの復元機能
- バックアップ成功/失敗通知（Phase 7.8のBackupMailer使用）

---

## 📚 用語集

- **Backup_System**: 自動バックアップシステム全体
- **Database_Backup**: PostgreSQL全テーブルのバックアップ（pg_dump -Fc | gzip形式）
- **Storage_Backup**: Active Storageディレクトリ（storage/）のバックアップ
- **Config_Backup**: 設定ファイル（.env, config/credentials.yml.enc）のバックアップ
- **S3_Bucket**: AWS S3バケット（portfolio-backup-miyakawa2449）
- **Backup_Type**: バックアップの種類（daily, weekly, monthly）
- **Retention_Policy**: 世代管理ポリシー（日次7日、週次4週、月次12ヶ月）
- **Restore_Operation**: バックアップからの復元操作
- **Backup_Mailer**: Phase 7.8で実装されたバックアップ通知用Mailer
- **Slack_Notifier**: Phase 7.8で実装されたSlack通知サービス

---

## 📝 要件

### 要件1: データベースバックアップ

**ユーザーストーリー**: 管理者として、PostgreSQLデータベースを自動的にバックアップしたい。データ損失リスクを最小化するため。

#### 受け入れ基準

1. WHEN 日次バックアップスケジュールが実行される THEN THE Backup_System SHALL PostgreSQL全テーブルをpg_dump -Fc形式でダンプする
2. WHEN データベースダンプを実行する THEN THE Backup_System SHALL 全スキーマ、全テーブル、全インデックス、全シーケンス、全制約を含める
3. WHEN データベースダンプを実行する THEN THE Backup_System SHALL active_storage_blobs、active_storage_attachments、active_storage_variant_recordsテーブルを含める
4. WHEN データベースダンプが完了する THEN THE Backup_System SHALL ダンプファイルをgzip圧縮する
5. WHEN 圧縮が完了する THEN THE Backup_System SHALL ファイル名に日時とバックアップタイプを含める（例: database_20260123_030000_daily.dump.gz）
6. WHEN バックアップファイルが生成される THEN THE Backup_System SHALL ファイルサイズを記録する
7. WHEN バックアップファイルが生成される THEN THE Backup_System SHALL チェックサムを計算して記録する
8. IF データベース接続に失敗する THEN THE Backup_System SHALL エラーログを記録し、Backup_Mailerで失敗通知を送信する

---

### 要件2: Active Storageバックアップ

**ユーザーストーリー**: 管理者として、アップロードされた画像ファイルを自動的にバックアップしたい。画像データの損失を防ぐため。

#### 受け入れ基準

1. WHEN 日次バックアップスケジュールが実行される THEN THE Backup_System SHALL storage/ディレクトリ全体をtar.gz形式でアーカイブする
2. WHEN アーカイブが完了する THEN THE Backup_System SHALL ファイル名に日時とバックアップタイプを含める（例: storage_20260123_030000_daily.tar.gz）
3. WHEN バックアップファイルが生成される THEN THE Backup_System SHALL ファイルサイズを記録する
4. IF storage/ディレクトリが存在しない THEN THE Backup_System SHALL 警告ログを記録し、空のアーカイブを作成する

---

### 要件3: 設定ファイルバックアップ

**ユーザーストーリー**: 管理者として、環境変数と暗号化された認証情報を自動的にバックアップしたい。システム復旧時に必要な設定を保持するため。

#### 受け入れ基準

1. WHEN 日次バックアップスケジュールが実行される THEN THE Backup_System SHALL .envファイルをバックアップする
2. WHEN 日次バックアップスケジュールが実行される THEN THE Backup_System SHALL .env.productionファイルをバックアップする
3. WHEN 日次バックアップスケジュールが実行される THEN THE Backup_System SHALL config/credentials.yml.encファイルをバックアップする
4. WHEN 日次バックアップスケジュールが実行される THEN THE Backup_System SHALL config/master.keyファイルをバックアップする
5. WHEN 設定ファイルのバックアップが完了する THEN THE Backup_System SHALL tar.gz形式でアーカイブする
6. WHEN アーカイブが完了する THEN THE Backup_System SHALL ファイル名に日時とバックアップタイプを含める（例: config_20260123_030000_daily.tar.gz）
7. IF 必須設定ファイル（.env、credentials.yml.enc）が存在しない THEN THE Backup_System SHALL エラーログを記録し、Backup_Mailerで失敗通知を送信する
8. IF オプション設定ファイル（master.key）が存在しない THEN THE Backup_System SHALL 警告ログを記録するが、バックアップ処理は継続する

---

### 要件4: AWS S3アップロード

**ユーザーストーリー**: 管理者として、バックアップファイルをAWS S3に暗号化して保存したい。セキュアなオフサイトバックアップを実現するため。

#### 受け入れ基準

1. WHEN バックアップファイルが生成される THEN THE Backup_System SHALL AWS S3バケット（portfolio-backup-miyakawa2449）にアップロードする
2. WHEN S3にアップロードする THEN THE Backup_System SHALL サーバーサイド暗号化（SSE-S3、AES-256）を有効にする
3. WHEN S3にアップロードする THEN THE Backup_System SHALL オブジェクトキーにバックアップタイプと日時を含める（例: daily/2026/01/23/database_20260123_030000_daily.dump.gz）
4. WHEN アップロードが完了する THEN THE Backup_System SHALL ローカルの一時ファイルを削除する
5. IF S3アップロードに失敗する THEN THE Backup_System SHALL 最大3回リトライする
6. IF 3回のリトライ後も失敗する THEN THE Backup_System SHALL エラーログを記録し、Backup_Mailerで失敗通知を送信する

---

### 要件5: バックアップスケジュール

**ユーザーストーリー**: 管理者として、日次・週次・月次のスケジュールでバックアップを自動実行したい。定期的なバックアップを確実に実施するため。

#### 受け入れ基準

1. THE Backup_System SHALL 毎日午前2時（JST）に日次バックアップを実行する
2. THE Backup_System SHALL 毎週日曜日午前3時（JST）に週次バックアップを実行する
3. THE Backup_System SHALL 毎月1日午前4時（JST）に月次バックアップを実行する
4. WHEN バックアップスケジュールが実行される THEN THE Backup_System SHALL Sidekiq-cronを使用してバックグラウンドジョブとして実行する
5. WHEN バックアップが完了する THEN THE Backup_System SHALL 実行時間をログに記録する

---

### 要件6: 世代管理

**ユーザーストーリー**: 管理者として、古いバックアップを自動的に削除したい。ストレージコストを最適化し、必要な世代のみを保持するため。

#### 受け入れ基準

1. WHEN 日次バックアップが完了する THEN THE Backup_System SHALL 7日より古い日次バックアップをS3から削除する
2. WHEN 週次バックアップが完了する THEN THE Backup_System SHALL 4週より古い週次バックアップをS3から削除する
3. WHEN 月次バックアップが完了する THEN THE Backup_System SHALL 12ヶ月より古い月次バックアップをS3から削除する
4. WHEN 古いバックアップを削除する THEN THE Backup_System SHALL 削除されたファイル名と日時をログに記録する
5. IF 削除処理に失敗する THEN THE Backup_System SHALL エラーログを記録するが、バックアップ処理は継続する

---

### 要件7: バックアップ通知

**ユーザーストーリー**: 管理者として、バックアップの成功・失敗を通知で受け取りたい。バックアップの状態を把握し、問題に迅速に対応するため。

#### 受け入れ基準

1. WHEN バックアップが成功する THEN THE Backup_System SHALL Backup_Mailerのbackup_successメソッドを呼び出す
2. WHEN バックアップが失敗する THEN THE Backup_System SHALL Backup_Mailerのbackup_failedメソッドを呼び出す
3. WHEN バックアップ通知を送信する THEN THE Backup_System SHALL バックアップタイプ、日時、ファイルサイズを含める
4. WHEN バックアップが成功する THEN THE Backup_System SHALL Slack_Notifierのnotify_backup_statusメソッドを呼び出す
5. IF メール送信に失敗する THEN THE Backup_System SHALL エラーログを記録するが、バックアップ処理は継続する

---

### 要件8: バックアップ一覧表示

**ユーザーストーリー**: 管理者として、管理画面でバックアップ一覧を確認したい。どのバックアップが利用可能かを把握するため。

#### 受け入れ基準

1. WHEN 管理者がバックアップ一覧ページにアクセスする THEN THE Backup_System SHALL S3から全バックアップのリストを取得する
2. WHEN バックアップ一覧を表示する THEN THE Backup_System SHALL 各バックアップの日時、タイプ、ファイルサイズを表示する
3. WHEN バックアップ一覧を表示する THEN THE Backup_System SHALL 最新のバックアップを上部に表示する
4. WHEN バックアップ一覧を表示する THEN THE Backup_System SHALL バックアップタイプでフィルタリングできる
5. IF S3からのリスト取得に失敗する THEN THE Backup_System SHALL エラーメッセージを表示する

---

### 要件9: バックアップ復元

**ユーザーストーリー**: 管理者として、管理画面からワンクリックでバックアップを復元したい。障害時に迅速に復旧するため。

#### 受け入れ基準

1. WHEN 管理者がバックアップ一覧で復元ボタンをクリックする THEN THE Backup_System SHALL 確認ダイアログを表示する
2. WHEN 管理者が復元を確認する THEN THE Backup_System SHALL S3から選択されたバックアップファイルをダウンロードする
3. WHEN データベースバックアップを復元する THEN THE Backup_System SHALL pg_restoreコマンドを使用してデータベースを復元する
4. WHEN Active Storageバックアップを復元する THEN THE Backup_System SHALL tar.gzを展開してstorage/ディレクトリに復元する
5. WHEN 設定ファイルバックアップを復元する THEN THE Backup_System SHALL tar.gzを展開して.envとcredentials.yml.encを復元する
6. WHEN 復元が完了する THEN THE Backup_System SHALL 復元ログを記録する
7. WHEN 復元が完了する THEN THE Backup_System SHALL Backup_Mailerのrestore_successメソッドを呼び出す
8. IF 復元処理に失敗する THEN THE Backup_System SHALL エラーログを記録し、Backup_Mailerのrestore_failedメソッドを呼び出す
9. WHEN 復元処理を実行する THEN THE Backup_System SHALL Sidekiqバックグラウンドジョブとして実行する

---

### 要件10: AWS S3セットアップガイド

**ユーザーストーリー**: 管理者として、AWS S3バケットを正しく設定したい。バックアップシステムを安全に運用するため。

#### 受け入れ基準

1. THE セットアップガイド SHALL S3バケット作成手順を含む
2. THE セットアップガイド SHALL サーバーサイド暗号化（SSE-S3）の有効化手順を含む
3. THE セットアップガイド SHALL バケットポリシー設定例を含む
4. THE セットアップガイド SHALL ライフサイクルルール設定手順を含む
5. THE セットアップガイド SHALL パブリックアクセスブロック設定手順を含む
6. THE セットアップガイド SHALL バージョニング設定手順を含む

---

### 要件11: IAM認証情報作成ガイド

**ユーザーストーリー**: 管理者として、AWS IAMユーザーを最小権限で作成したい。セキュリティベストプラクティスに従うため。

#### 受け入れ基準

1. THE セットアップガイド SHALL IAMユーザー作成手順を含む
2. THE セットアップガイド SHALL S3アクセス権限設定例を含む（最小権限の原則）
3. THE セットアップガイド SHALL アクセスキー発行手順を含む
4. THE セットアップガイド SHALL 環境変数設定手順を含む（AWS_BACKUP_ACCESS_KEY_ID、AWS_BACKUP_SECRET_ACCESS_KEY、AWS_BACKUP_REGION、S3_BACKUP_BUCKET）
5. THE セットアップガイド SHALL アクセスキーの安全な管理方法を含む
6. THE セットアップガイド SHALL バックアップ用IAMユーザーは他のAWSサービス（SES、Bedrock等）のIAMユーザーとは別に作成することを明記する

---

### 要件12: コスト見積もり

**ユーザーストーリー**: 管理者として、AWS S3のコストを事前に把握したい。予算内で運用するため。

#### 受け入れ基準

1. THE セットアップガイド SHALL S3ストレージコストの計算例を含む
2. THE セットアップガイド SHALL データ転送コストの計算例を含む
3. THE セットアップガイド SHALL 月額予算目安を含む
4. THE セットアップガイド SHALL コスト最適化のヒントを含む

---

### 要件13: セキュリティ設定

**ユーザーストーリー**: 管理者として、S3バケットを安全に設定したい。不正アクセスやデータ漏洩を防ぐため。

#### 受け入れ基準

1. THE セットアップガイド SHALL バケットのパブリックアクセスブロック設定手順を含む
2. THE セットアップガイド SHALL バージョニング設定手順を含む
3. THE セットアップガイド SHALL MFA Delete設定手順を含む（オプション）
4. THE セットアップガイド SHALL バケットポリシーのセキュリティベストプラクティスを含む
5. THE セットアップガイド SHALL アクセスログ設定手順を含む（オプション）

---

### 要件14: AWS認証情報の分離

**ユーザーストーリー**: 管理者として、AWS認証情報をサービスごとに分離したい。最小権限の原則を徹底し、認証情報の誤設定による障害を防ぐため。

#### 受け入れ基準

1. THE Backup_System SHALL バックアップ専用の環境変数プレフィックス（AWS_BACKUP_*）を使用する
2. THE Backup_System SHALL SES用（AWS_SES_*）、Bedrock用（AWS_BEDROCK_*）、S3バックアップ用（AWS_BACKUP_*）の認証情報を明確に分離する
3. THE Backup_System SHALL 汎用環境変数（AWS_ACCESS_KEY_ID、AWS_SECRET_ACCESS_KEY）に依存しない
4. THE セットアップガイド SHALL 各AWSサービスのIAMユーザーと環境変数の対応表を含む
5. IF docker-compose.ymlのenvironment:で環境変数を明示的に指定する場合 THEN .env.productionに対応する値が設定されていることを確認する手順を含む

---

### 要件15: デプロイ手順

**ユーザーストーリー**: 管理者として、バックアップシステムを含むデプロイを安全に実行したい。デプロイ時の502エラーやサービス停止を防ぐため。

#### 受け入れ基準

1. WHEN --keep-sslモードでデプロイする THEN THE deploy.sh SHALL nginxの再起動後にhttps-portalを再起動してIPアドレスの変更を反映する
2. THE deploy.sh SHALL デプロイ後にバックアップ関連の環境変数（AWS_BACKUP_*）がコンテナに正しく渡されていることを確認する手順を含む
3. THE セットアップガイド SHALL 初回デプロイ時のチェックリスト（環境変数設定、IAMユーザー作成、S3バケット作成）を含む

---

## 📚 参考資料

### 関連ドキュメント
- [Phase 7 要件定義書](../.kiro/specs/phase-7-security-operations/requirements.md)
- [Phase 7.8 最終レビュー](../../../reports/2026-01-23/kiro-phase7.8-final-review.md)
- [Phase 5.8 データベースエクスポート/インポート](../.kiro/specs/phase-5.8-database-export-import/requirements.md)

### 技術資料
- [AWS SDK for Ruby - S3](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3.html)
- [PostgreSQL pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)
- [PostgreSQL pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html)
- [Sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron)

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-01-23  
**🔄 バージョン**: v1.0  
**📋 ステータス**: 要件定義中
