# Phase 7.3 自動バックアップシステム - 本番デプロイレポート

**日付**: 2026年4月21日（火）  
**担当**: Kiro（仕様管理・レビュー）、Claude Code（本番サーバー調査・修正）  
**Phase**: 7.3 自動バックアップシステム  
**ステータス**: ✅ 本番デプロイ完了・自動バックアップ稼働開始

---

## 📊 本日の作業サマリー

| # | 問題 | 原因 | 対処 | 担当 |
|---|------|------|------|------|
| 1 | 502エラー | https-portalがnginx再作成後の新IPを認識できず | https-portal再起動、deploy.shに自動再起動追加 | Claude Code + Kiro |
| 2 | S3認証エラー | AWS_BACKUP_ACCESS_KEY_IDにSESユーザーのキーが誤設定 | 専用IAMユーザー miyakawa-codes-s3-backup を作成 | Claude Code |
| 3 | Bedrock AI機能停止 | .env.productionにAWS_BEDROCK_*がなく空文字で上書き | .env.productionに追記 | Claude Code |
| 4 | AWS認証情報のグローバル干渉 | aws_ses.rbがAws.config.update()でグローバル設定 | sesv2_settingsでSESクライアントにスコープ | Kiro |
| 5 | ナビゲーションにバックアップリンクなし | 実装漏れ | _navigation.html.erbにリンク追加 | Kiro |
| 6 | Sidekiq-cronが動かない | 本番はSolid Queue、Redisなし | config/recurring.ymlにスケジュール登録 | Claude Code |

---

## 🔍 問題1: 502エラー

### 症状
デプロイ後、サイト全体が502 Bad Gatewayを返す。

### 原因
`docker compose up -d`でnginxコンテナが再作成されると新しいIPが割り当てられるが、https-portalは再起動されないため古いIPに接続し続けていた。

### 対処
- 即時対応: `docker compose restart https-portal`
- 恒久対応: `scripts/deploy.sh`の`start_services_except_ssl`関数にhttps-portal再起動を追加

```bash
# nginxが再作成されるとIPが変わるため、https-portalを再起動して
# 新しいIPを解決させる（502エラー防止）
echo "  Restarting https-portal to pick up new nginx IP..."
dc restart https-portal
```

---

## 🔍 問題2: S3バックアップ認証エラー

### 症状
管理画面のバックアップページで「User: arn:aws:iam::901559187776:user/miyakawa-codes-sendmail is not authorized to perform: s3:ListBucket」エラー。

### 原因
`.env.production`の`AWS_BACKUP_ACCESS_KEY_ID`にSESメール送信用IAMユーザー（miyakawa-codes-sendmail）のキーが誤って設定されていた。

### 対処
- S3バックアップ専用IAMユーザー `miyakawa-codes-s3-backup` を新規作成
- `PortfolioBackupS3Policy`（s3:PutObject, GetObject, DeleteObject, ListBucket）をアタッチ
- `.env.production`のAWS_BACKUP_*を正しいキーに更新

---

## 🔍 問題3: Bedrock AI機能停止

### 症状
AI機能（記事要約、SEOメタ生成等）が動作しない。

### 原因
`.env.production`に`AWS_BEDROCK_*`環境変数が未設定。`docker-compose.production.yml`の`environment:`セクションで`${AWS_BEDROCK_ACCESS_KEY_ID}`が空文字に展開され、Bedrockクライアントの認証情報が無効になっていた。

### 対処
`.env.production`にBedrock用環境変数を追記。

---

## 🔍 問題4: AWS認証情報のグローバル干渉

### 症状
SESの認証情報がS3やBedrockのクライアントに干渉し、意図しないIAMユーザーで認証される。

### 原因
`config/initializers/aws_ses.rb`が`Aws.config.update()`でSESの認証情報をグローバルに設定していた。AWS SDKの認証情報チェーンにより、他のサービスクライアント（S3、Bedrock）もこのグローバル設定を参照していた。

### 対処
`Aws.config.update()`を削除し、`config.action_mailer.sesv2_settings`でSESクライアントにのみ認証情報をスコープ。

```ruby
# 修正前（グローバル設定 — 他サービスに干渉）
Aws.config.update(
  region: ENV.fetch("AWS_SES_REGION", "ap-northeast-1"),
  credentials: Aws::Credentials.new(...)
)

# 修正後（SESクライアントにスコープ）
config.action_mailer.sesv2_settings = {
  region: ses_region,
  credentials: Aws::Credentials.new(...)
}
```

### 修正後の認証情報フロー

| サービス | IAMユーザー | 環境変数 | スコープ |
|---------|------------|---------|---------|
| SES | miyakawa-codes-sendmail | AWS_SES_* | sesv2_settingsでSESクライアントのみ |
| S3 | miyakawa-codes-s3-backup | AWS_BACKUP_* | S3Service#initializeで明示的に渡す |
| Bedrock | （Bedrock用ユーザー） | AWS_BEDROCK_* | BedrockClient#build_clientで明示的に渡す |

---

## 🔍 問題5: ナビゲーションにバックアップリンクなし

### 症状
管理画面にログインしてもバックアップページへの導線がない。

### 原因
`app/views/admin/shared/_navigation.html.erb`にバックアップページへのリンクが追加されていなかった（実装漏れ）。

### 対処
「システム設定」セクションの先頭に「バックアップ」リンクを追加。

---

## 🔍 問題6: Sidekiq-cronが動かない（スケジュール未登録）

### 症状
Sidekiq-cronジョブの確認コマンドでRedis接続エラー。バックアップスケジュールが登録されていない。

### 原因
本番環境はSolid Queue（データベースベース）をジョブキューに使用しており、Redisは存在しない。Sidekiq-cronはRedis依存のため動作しない。`sidekiq_cron.rb`のガード条件`return if ENV["REDIS_URL"].blank?`でスキップされていた。

### 対処
`config/recurring.yml`（Solid Queueのスケジューラ設定）にバックアップスケジュールを登録。

---

## 📋 仕様書の調整

### requirements.md
- 要件11.4: 環境変数名を`AWS_ACCESS_KEY_ID` → `AWS_BACKUP_ACCESS_KEY_ID`に修正
- 要件11.6: 追加 — バックアップ用IAMユーザーは他サービスと別に作成することを明記
- 要件14: 新規追加 — AWS認証情報の分離
- 要件15: 新規追加 — デプロイ手順
- 要件5: スケジュール時間を更新（daily 2:00、weekly 3:00、monthly 4:00）

### design.md
- IAMガイドの環境変数名を`AWS_BACKUP_*`プレフィックスに統一
- AWS認証情報の分離表を追加
- docker-compose.ymlのenvironment:空文字上書き問題の注意書きを追加
- スケジュール時間を更新

### .env.production.example
- `AWS_ACCESS_KEY_ID` → `AWS_SES_ACCESS_KEY_ID`に変更
- `AWS_BEDROCK_*`環境変数を追加

### .env.example
- `AWS_ACCESS_KEY_ID`がSDKのデフォルト認証情報チェーンで干渉する可能性の注意書きを追加

---

## ✅ 最終状態

### 本番環境のスケジュール

```
daily_backup:   every day at 2:00 Asia/Tokyo (Backup::DailyBackupJob)
weekly_backup:  every sunday at 3:00 Asia/Tokyo (Backup::WeeklyBackupJob)
monthly_backup: 0 4 1 * * Asia/Tokyo (Backup::MonthlyBackupJob)
```

Lightsail負荷分散のため、意図的に時間をずらしています。

### 確認済み項目

- ✅ 全コンテナ起動中（portfolio-web、portfolio-worker、portfolio-db、nginx、https-portal）
- ✅ SES認証情報がスコープされ、S3/Bedrockに干渉しない
- ✅ S3バックアップ専用IAMユーザーで認証成功
- ✅ Bedrock AI機能復旧
- ✅ 管理画面にバックアップリンク表示
- ✅ Solid Queueのrecurring tasksにバックアップスケジュール登録済み
- ✅ 198件のテスト全通過（ローカル）

### 明朝の確認事項

- 管理画面のバックアップページでS3にファイルが上がっているか確認
- BackupLogにsuccess記録があるか確認

---

## 👥 役割分担

### Kiro（仕様管理）
- ✅ aws_ses.rbのグローバル認証情報干渉を修正
- ✅ ナビゲーションにバックアップリンク追加
- ✅ 仕様書の調整（requirements.md、design.md）
- ✅ .env.example、.env.production.exampleの修正
- ✅ deploy.shにhttps-portal再起動追加

### Claude Code（本番サーバー調査・修正）
- ✅ 502エラーの根本原因特定（Docker networking）
- ✅ S3認証エラーの調査・IAMユーザー作成
- ✅ Bedrock環境変数の追記
- ✅ Solid Queue recurring tasksへのスケジュール登録

---

## 📝 教訓

1. **AWS認証情報はグローバルに設定しない** — `Aws.config.update()`は全クライアントに影響する。各サービスのクライアントに直接渡すか、delivery method固有の設定を使う。

2. **環境変数のプレフィックスで責務を分離する** — `AWS_SES_*`、`AWS_BEDROCK_*`、`AWS_BACKUP_*`のように、サービスごとにプレフィックスを付けて干渉を防ぐ。

3. **docker-compose.ymlのenvironment:は空文字で上書きする** — `${VAR}`が.envに未定義の場合、空文字が設定される。デプロイ前に`env | grep`で確認する。

4. **ジョブキューとスケジューラの整合性を確認する** — Solid Queue環境ではSidekiq-cronは動かない。`config/recurring.yml`を使う。

5. **--keep-sslデプロイ後はhttps-portalを再起動する** — nginxのIP変更をhttps-portalに反映させる。

---

**レポート作成日**: 2026年4月21日  
**作成者**: Kiro（仕様管理担当）
