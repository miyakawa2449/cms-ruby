# バックアップ・復元手順書

**バージョン**: 1.0  
**作成日**: 2026年4月21日  
**対象**: Phase 7.3 自動バックアップシステム  
**実装者**: Claude Code / Codex  
**レビュー**: Kiro（仕様管理担当）

---

## 📋 目次

1. [システム概要](#1-システム概要)
2. [バックアップ手順](#2-バックアップ手順)
   - [自動バックアップの仕組み](#21-自動バックアップの仕組み)
   - [手動バックアップの実行方法](#22-手動バックアップの実行方法)
   - [バックアップの確認方法](#23-バックアップの確認方法)
3. [復元手順](#3-復元手順)
   - [管理画面からの復元](#31-管理画面からの復元)
   - [コマンドラインからの復元](#32-コマンドラインからの復元)
   - [復元後の確認事項](#33-復元後の確認事項)
4. [トラブルシューティング](#4-トラブルシューティング)
   - [よくあるエラーと解決方法](#41-よくあるエラーと解決方法)
   - [ログの確認方法](#42-ログの確認方法)
5. [災害復旧計画（DR Plan）](#5-災害復旧計画dr-plan)
   - [復旧手順](#51-復旧手順)
   - [復旧優先順位](#52-復旧優先順位)
   - [連絡体制](#53-連絡体制)

---

## 1. システム概要

### バックアップ対象

| カテゴリ | 対象 | 形式 |
|---------|------|------|
| **データベース** | PostgreSQL 全テーブル | `pg_dump -Fc` + gzip圧縮 |
| **ストレージ** | `storage/` ディレクトリ（Active Storage） | tar.gz アーカイブ |
| **設定ファイル** | `.env`、`config/credentials.yml.enc` | tar.gz アーカイブ |

### バックアップスケジュール

| 種別 | 実行タイミング | 保持期間 |
|-----|-------------|---------|
| **日次 (daily)** | 毎日 午前3:00 JST | 7日間 |
| **週次 (weekly)** | 毎週日曜日 午前3:00 JST | 28日間（4週） |
| **月次 (monthly)** | 毎月1日 午前3:00 JST | 365日間（12ヶ月） |

### S3保存先

```
s3://portfolio-backup-miyakawa-codes/
├── daily/
│   └── YYYY/MM/DD/
│       ├── database_database_YYYYMMDD_HHMMSS_daily.dump.gz
│       ├── storage_storage_YYYYMMDD_HHMMSS_daily.tar.gz
│       └── config_config_YYYYMMDD_HHMMSS_daily.tar.gz
├── weekly/
│   └── YYYY/MM/DD/
│       └── ...（同形式）
└── monthly/
    └── YYYY/MM/DD/
        └── ...（同形式）
```

---

## 2. バックアップ手順

### 2.1 自動バックアップの仕組み

自動バックアップは **Sidekiq-cron** によって管理されています。

#### 処理フロー

```
Sidekiq-cron（スケジューラー）
    ↓ 定刻になると起動
Backup::DailyBackupJob（Sidekiqキュー: backup）
    ↓ ジョブ実行
BackupService
    ├── DatabaseBackupService  → pg_dump → gzip → tmp/backup/
    ├── StorageBackupService   → tar -czf → tmp/backup/
    └── ConfigBackupService    → ファイルコピー → tar -czf → tmp/backup/
        ↓ 各ファイルを S3 にアップロード（SSE-S3 暗号化、最大3回リトライ）
S3Service
        ↓ 保持期間超えのバックアップを削除
S3RetentionManager
        ↓ 完了通知
BackupMailer / SlackNotifier
        ↓ 一時ファイルをクリーンアップ
tmp/backup/ 削除
```

#### Sidekiq-cron設定ファイル

```ruby
# config/initializers/sidekiq_cron.rb
"daily_backup" => {
  "class" => "Backup::DailyBackupJob",
  "cron"  => "0 3 * * *",    # 毎日午前3時 JST
  "queue" => "backup"
}
"weekly_backup" => {
  "class" => "Backup::WeeklyBackupJob",
  "cron"  => "0 3 * * 0",    # 毎週日曜日午前3時 JST
  "queue" => "backup"
}
"monthly_backup" => {
  "class" => "Backup::MonthlyBackupJob",
  "cron"  => "0 3 1 * *",    # 毎月1日午前3時 JST
  "queue" => "backup"
}
```

> **注意**: Sidekiq が起動していないとバックアップは実行されません。`systemctl status sidekiq` で稼働状態を確認してください。

### 2.2 手動バックアップの実行方法

#### Rails コンソールから実行

```bash
# Dockerコンテナにアクセス
docker compose exec web rails console

# 日次バックアップを手動実行
BackupService.new(backup_type: "daily").execute

# 週次バックアップを手動実行
BackupService.new(backup_type: "weekly").execute

# 月次バックアップを手動実行
BackupService.new(backup_type: "monthly").execute
```

#### Sidekiq キューにジョブを投入

```ruby
# Rails コンソール内
Backup::DailyBackupJob.perform_later
Backup::WeeklyBackupJob.perform_later
Backup::MonthlyBackupJob.perform_later
```

#### 実行ログの確認

```bash
# Sidekiqログを確認
docker compose logs sidekiq --tail=100

# Railsログを確認
docker compose exec web tail -f log/production.log | grep BackupService
```

### 2.3 バックアップの確認方法

#### 管理画面から確認

1. 管理画面にログイン: `https://your-domain.com/admin-secure-panel-miyakawa2449`
2. サイドメニューから「バックアップ管理」をクリック
3. **S3バックアップファイル一覧**でファイルの有無・日時・サイズを確認
4. フィルター（日次/週次/月次）で絞り込み可能
5. **バックアップ実行ログ（直近20件）** で過去の実行結果とステータスを確認

#### BackupLog モデルから確認

```ruby
# Rails コンソール内

# 最新10件のバックアップログを確認
BackupLog.recent.limit(10).each do |log|
  puts "#{log.started_at} | #{log.backup_type} | #{log.status} | #{log.file_size_mb}MB"
end

# 失敗したバックアップを確認
BackupLog.failed.each { |log| puts "#{log.started_at}: #{log.error_message}" }

# 直近の成功バックアップ
BackupLog.success.recent.first
```

#### AWS コンソールから直接確認

1. AWS Management Console にログイン
2. S3 → `portfolio-backup-miyakawa-codes` バケット
3. フォルダ（daily/weekly/monthly）を展開してファイルを確認

---

## 3. 復元手順

> ⚠️ **警告**: 復元操作は現在のデータベース・ファイルを上書きします。  
> 復元前に必ず現状のバックアップを取得することを推奨します。

### 3.1 管理画面からの復元

最も簡単な復元方法です。

#### 手順

1. **管理画面にログイン**
   - `https://your-domain.com/admin-secure-panel-miyakawa2449`

2. **バックアップ管理ページを開く**
   - サイドメニューから「バックアップ管理」をクリック

3. **復元対象を選択**
   - S3バックアップファイル一覧から復元したい日付のエントリを探す
   - フィルターで `daily`/`weekly`/`monthly` を絞り込むと見つけやすい
   - 対象行の「復元」ボタンをクリック

4. **確認モーダルで復元を承認**
   - 警告メッセージを確認
   - 復元対象のS3キーと日時を確認
   - 「復元する」ボタンをクリック

5. **バックグラウンドジョブの完了を待つ**
   - `Restore::RestoreJob` がキューに追加され、バックグラウンドで処理される
   - 完了後にメール通知が届く（設定済みの場合）
   - BackupLog で `restore` タイプのエントリが `success` になれば完了

> **重要**: 復元は database/storage/config の**3ファイルをセットで**行います。  
> いずれかのファイルが S3 に存在しない場合はスキップされます。

### 3.2 コマンドラインからの復元

管理画面にアクセスできない場合や、特定のファイルのみ復元したい場合に使用します。

#### S3 からバックアップキーを確認

```ruby
# Rails コンソール内
s3 = S3Service.new

# 利用可能なバックアップ一覧を表示
s3.list_backups.each { |b| puts "#{b[:last_modified].in_time_zone('Asia/Tokyo')} | #{b[:key]}" }

# 日次のみ表示
s3.list_backups(backup_type: "daily").each { |b| puts b[:key] }
```

#### 全カテゴリを一括復元

```ruby
# Rails コンソール内

backup_keys = {
  database: "daily/2026/04/20/database_database_20260420_030000_daily.dump.gz",
  storage:  "daily/2026/04/20/storage_storage_20260420_030000_daily.tar.gz",
  config:   "daily/2026/04/20/config_config_20260420_030000_daily.tar.gz"
}

RestoreService.new(backup_keys: backup_keys).execute
```

#### 個別サービスでの復元（上級者向け）

```bash
# S3 からローカルにダウンロード
aws s3 cp s3://portfolio-backup-miyakawa-codes/daily/2026/04/20/database_...dump.gz /tmp/

# データベースのみ復元（Rails コンソール内）
DatabaseRestoreService.new("/tmp/database_20260420_030000_daily.dump.gz").execute

# ストレージのみ復元
StorageRestoreService.new("/tmp/storage_20260420_030000_daily.tar.gz").execute

# 設定ファイルのみ復元
ConfigRestoreService.new("/tmp/config_20260420_030000_daily.tar.gz").execute
```

### 3.3 復元後の確認事項

#### データベース確認

```ruby
# Rails コンソール内

# テーブル数を確認
ActiveRecord::Base.connection.tables.count

# 主要テーブルのレコード数を確認
puts "Articles: #{Article.count}"
puts "Categories: #{Category.count}"
puts "AdminUsers: #{AdminUser.count}"
```

#### ストレージ確認

```bash
# storage/ ディレクトリの容量確認
du -sh storage/

# ファイル数確認
find storage/ -type f | wc -l
```

#### アプリケーション動作確認

```bash
# サービス再起動（設定ファイルを復元した場合は必須）
docker compose restart web sidekiq

# ヘルスチェック
curl https://your-domain.com/up
```

#### BackupLog で復元結果を確認

```ruby
# Rails コンソール内
restore_log = BackupLog.where(backup_type: "restore").order(started_at: :desc).first
puts "Status: #{restore_log.status}"
puts "Duration: #{restore_log.duration.to_i}秒"
puts "Error: #{restore_log.error_message}" if restore_log.failed?
```

---

## 4. トラブルシューティング

### 4.1 よくあるエラーと解決方法

#### エラー: バックアップが実行されない

**症状**: 毎日3時になってもバックアップが実行されない

**確認・解決手順**:

```bash
# 1. Sidekiq が起動しているか確認
docker compose ps sidekiq

# 2. Sidekiq ログで Cron ジョブを確認
docker compose logs sidekiq | grep -E "daily_backup|weekly_backup|monthly_backup"

# 3. Sidekiq-cron のジョブリストを確認（Rails コンソール）
Sidekiq::Cron::Job.all.each { |j| puts "#{j.name}: #{j.next_time}" }

# 4. Sidekiq を再起動
docker compose restart sidekiq
```

---

#### エラー: S3 アップロード失敗（Access Denied）

**症状**: `Aws::S3::Errors::AccessDenied` ログが出る

**確認・解決手順**:

```bash
# 1. 環境変数を確認
docker compose exec web env | grep AWS_BACKUP

# 2. IAM ポリシーを確認（AWS コンソールで PortfolioBackupS3Policy を確認）

# 3. 手動でアップロードテスト（Rails コンソール）
S3Service.new.list_backups
```

---

#### エラー: 設定ファイルが見つからない

**症状**: `Required config files missing: .env, config/credentials.yml.enc`

**原因**: バックアップ実行時に必須ファイルが存在しない

**解決方法**:

```bash
# 必須ファイルの存在を確認
ls -la .env config/credentials.yml.enc

# .env が存在しない場合はサンプルからコピー
cp .env.example .env
# 内容を適切に編集
```

---

#### エラー: pg_dump が失敗する

**症状**: `Database dump failed with exit code N`

**確認・解決手順**:

```bash
# 1. PostgreSQL への接続確認
docker compose exec web rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"

# 2. pg_dump コマンドの確認
docker compose exec web pg_dump --version

# 3. DATABASE_URL の確認
docker compose exec web env | grep DATABASE_URL
```

---

#### エラー: 復元後にアプリが起動しない

**症状**: 復元後に Rails アプリがエラーになる

**考えられる原因と対処**:

```bash
# 1. credentials が変わった場合は master.key も必要
# master.key を安全な場所から取得して配置

# 2. マイグレーション状態の確認
docker compose exec web rails db:migrate:status

# 3. マイグレーション差分がある場合
docker compose exec web rails db:migrate

# 4. アプリを再起動
docker compose restart web
```

---

#### エラー: ストレージ復元後にファイルが表示されない

**症状**: Active Storage のファイルが 404 になる

**確認**:

```bash
# ファイルが正しい場所に復元されているか確認
ls storage/

# パーミッション確認
ls -la storage/
```

---

### 4.2 ログの確認方法

#### バックアップ実行ログ（管理画面）

1. 管理画面 → バックアップ管理 → 画面下部の「バックアップ実行ログ」セクション
2. 直近20件の実行履歴（開始時刻、タイプ、ステータス、所要時間、ファイルサイズ）が表示される

#### Rails ログからの確認

```bash
# production.log でバックアップ関連を抽出
docker compose exec web grep -E "BackupService|DatabaseBackup|StorageBackup|ConfigBackup|S3Service|RestoreService" log/production.log | tail -50

# エラーのみ抽出
docker compose exec web grep "ERROR" log/production.log | grep -E "Backup|Restore" | tail -20
```

#### Sidekiq ログからの確認

```bash
# Sidekiq ジョブの実行ログ
docker compose logs sidekiq | grep -E "DailyBackupJob|WeeklyBackupJob|MonthlyBackupJob|RestoreJob"
```

#### BackupLog データベースからの確認

```ruby
# Rails コンソール内

# 全バックアップログ（直近30件）
BackupLog.recent.limit(30).each do |log|
  status_icon = log.success? ? "✅" : log.failed? ? "❌" : "⏳"
  puts "#{status_icon} #{log.started_at.in_time_zone('Asia/Tokyo').strftime('%Y/%m/%d %H:%M')} | #{log.backup_type} | #{log.duration&.to_i}秒"
  puts "   エラー: #{log.error_message}" if log.failed?
end
```

---

## 5. 災害復旧計画（DR Plan）

### 目標値

| 指標 | 目標値 | 説明 |
|-----|--------|------|
| **RTO（目標復旧時間）** | 4時間以内 | 障害発生から通常運用再開まで |
| **RPO（目標復旧時点）** | 24時間以内 | 最大でも前日の日次バックアップまで復旧可能 |

### 5.1 復旧手順

#### フェーズ1: 状況確認（0〜30分）

```bash
# 1. 障害の範囲を特定
docker compose ps                    # コンテナ稼働状態
docker compose logs web | tail -50   # アプリエラーログ
docker compose exec web rails runner "puts ActiveRecord::Base.connected?"  # DB接続確認

# 2. 最新バックアップの日時を確認（Rails コンソール）
BackupLog.success.recent.first.tap { |l| puts "最新バックアップ: #{l.started_at}" }
```

#### フェーズ2: インフラ復旧（30分〜2時間）

```bash
# Docker / サーバーレベルの問題の場合
docker compose down
docker compose up -d

# データが破損している場合は次のフェーズへ
```

#### フェーズ3: データ復元（2〜4時間）

```bash
# 1. 利用可能な最新バックアップを確認
docker compose exec web rails runner "
  S3Service.new.list_backups(backup_type: 'daily').first(3).each { |b| puts b[:key] }
"

# 2. 復元実行（Rails コンソール）
docker compose exec web rails console
```

```ruby
# Rails コンソール内
# 最新の日次バックアップで復元
latest = S3Service.new.list_backups(backup_type: "daily").max_by { |b| b[:last_modified] }
prefix = latest[:key].split("/").first(4).join("/") + "/"

all_keys = S3Service.new.list_backups(backup_type: "daily").select { |b| b[:key].start_with?(prefix) }

backup_keys = {
  database: all_keys.find { |b| b[:key].include?("/database_") }&.dig(:key),
  storage:  all_keys.find { |b| b[:key].include?("/storage_") }&.dig(:key),
  config:   all_keys.find { |b| b[:key].include?("/config_") }&.dig(:key)
}

puts "復元対象キー: #{backup_keys}"
RestoreService.new(backup_keys: backup_keys).execute
```

```bash
# 3. アプリを再起動
docker compose restart web sidekiq

# 4. 動作確認
curl https://your-domain.com/up
```

### 5.2 復旧優先順位

| 優先度 | 対象 | 理由 |
|--------|------|------|
| **1（最優先）** | データベース | サービス提供の根幹。記事・ユーザーデータ |
| **2（高）** | 設定ファイル（.env） | アプリ起動に必須。DB接続情報・APIキー |
| **3（中）** | ストレージ（Active Storage） | 画像等。DB が復元されれば参照自体は可能 |

> **データベースのみ先行復元する場合**:
> ```ruby
> DatabaseRestoreService.new("/path/to/database.dump.gz").execute
> docker compose restart web
> ```

### 5.3 連絡体制

| 役割 | タイミング |
|------|-----------|
| システム管理者への報告 | 障害検知後、直ちに |
| 復旧作業開始の報告 | 作業開始時 |
| 復旧完了報告 | サービス再開確認後 |
| 障害報告書の作成 | 復旧後24時間以内 |

#### バックアップ通知メールの確認

バックアップの成功・失敗は `BackupMailer` によってメール通知されます。

- **成功通知**: 件名「[Portfolio] バックアップ完了」
- **失敗通知**: 件名「[Portfolio] バックアップ失敗 - 要対応」

失敗通知を受け取った場合は、[4.2 ログの確認方法](#42-ログの確認方法) を参照してエラー内容を確認してください。

---

## 関連ドキュメント

- [AWS S3セットアップガイド](./aws_s3_setup_guide.md)
- [デプロイメントガイド](./deployment/DEPLOYMENT_GUIDE.md)
- [Phase 7.3 設計書](../.kiro/specs/phase-7.3-auto-backup/design.md)

---

**作成日**: 2026年4月21日  
**更新日**: 2026年4月21日  
**バージョン**: 1.0
