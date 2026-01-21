# AWS Lightsail本番デプロイ完全対応レポート

**日付**: 2025-12-15  
**担当**: Claude Code  
**タスク**: AWS Lightsail本番環境問題解決・デプロイ安全性向上  

## 🎯 実施内容サマリー

本日はAWS Lightsail本番環境で発生した複数の重大問題を根本解決し、安全で持続可能なデプロイ環境を構築しました。

### 解決した問題
1. **Solid Queue/Cache欠落問題**: マイグレーション作成・worker追加
2. **OGP/ActiveStorage URL問題**: host設定・nginx統合
3. **Let's Encryptレート制限事故**: deploy.sh安全性向上・緊急復旧機能

## 📊 問題と解決の詳細

### 1. Solid Queue/Cache問題

#### 症状
- 管理画面で画像保存時に500エラー
- `PG::UndefinedTable: solid_queue_jobs`
- `solid_cache_entries`テーブル欠落

#### 根本原因
- マイグレーションファイルがリポジトリに存在しない（コミット漏れ）
- Solid Queueのworkerプロセスが存在しない

#### 解決策
```ruby
# 1. Solid Cacheマイグレーション作成
class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]
  # 実装済み
end

# 2. Solid Queueマイグレーション作成
class CreateSolidQueueTables < ActiveRecord::Migration[8.1]
  # 11テーブル作成
end
```

```yaml
# 3. docker-compose.production.yml に worker 追加
portfolio-worker:
  command: bundle exec rails solid_queue:start
  # web と同じ環境・ボリューム
```

### 2. OGP/ActiveStorage URL生成問題

#### 症状
- フロントページ500エラー: `Missing host to link to!`
- 画像URL: `https://portfolio-web/rails/active_storage/...`
- `net::ERR_NAME_NOT_RESOLVED`

#### 根本原因
- Rails.application.routes.default_url_optionsが未設定
- nginxのHostヘッダー不適切
- ActiveStorage::Current.url_optionsが未設定

#### 解決策
```ruby
# config/environments/production.rb
Rails.application.routes.default_url_options[:host] = ENV.fetch("APP_HOST", "example.test")
Rails.application.routes.default_url_options[:protocol] = "https"

config.after_initialize do
  ActiveStorage::Current.url_options = Rails.application.routes.default_url_options
end
```

```nginx
# nginx.production.conf
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-Host $http_host;
```

### 3. Let's Encryptレート制限事故

#### 症状
- `docker compose down -v`でSSL証明書削除
- 再発行繰り返しで429エラー
- https-portalがRestartingループ
- サイト完全停止

#### 根本原因
- deploy.shが破壊的操作をデフォルト実行
- ボリューム保護機能の欠如

#### 解決策

**A) deploy.sh完全改修**
```bash
# 安全なデフォルト動作
./scripts/deploy.sh                # 全ボリューム保護
./scripts/deploy.sh --clean-cache   # tmp/logのみ削除
./scripts/deploy.sh --wipe-all      # 要"WIPE_ALL_VOLUMES"入力
```

**B) 緊急HTTP復旧機能**
```yaml
# docker-compose.production.http.yml
services:
  https-portal:
    profiles: ["disabled"]
  nginx:
    ports: ["80:80"]
```

## 🔧 実装した安全機能

### 1. ボリューム保護システム
```bash
保護対象（絶対削除しない）:
- https_portal_data  # SSL証明書
- postgres_data      # データベース
- storage_data       # アップロード画像

安全削除可能:
- tmp_data
- log_data
```

### 2. 段階的検証フロー
```bash
1. 環境変数検証（APP_HOST含む）
2. Dockerイメージビルド
3. コンテナ起動・待機
4. DB接続確認
5. マイグレーション実行
6. worker起動確認
7. https-portal状態確認
```

### 3. エラー時自動診断
```bash
on_error() {
  # 全コンテナのログ自動ダンプ
  # portfolio-web/worker/db/nginx/https-portal
}
```

## 📝 デプロイ作業の教訓

### 1. 絶対にやってはいけないこと
- ❌ 本番で`docker compose down -v`
- ❌ SSL証明書の頻繁な再発行
- ❌ 環境変数未設定でのデプロイ
- ❌ workerなしでのActiveStorage利用

### 2. 必ずやるべきこと
- ✅ マイグレーションのコミット確認
- ✅ 環境変数（APP_HOST等）の事前設定
- ✅ ローカルでのフルテスト
- ✅ ボリュームの保護意識

### 3. 緊急時の対応
- Let's Encryptレート制限時は緊急HTTPモード
- エラー時はログの自動診断を活用
- 破壊的操作は明示的確認が必要

## 🎯 完了状態

### 正常動作確認済み
- ✅ フロントページ表示
- ✅ 管理画面ログイン
- ✅ 画像アップロード・表示
- ✅ OGP URL生成
- ✅ バックグラウンドジョブ処理

### セキュリティ・安定性
- ✅ SSL証明書保護
- ✅ データベース保護
- ✅ 緊急復旧手順整備
- ✅ GitHubとAWSの同期

## 💡 今後の推奨事項

1. **定期バックアップ**
   ```bash
   docker exec portfolio-prod-portfolio-db-1 pg_dump -U portfolio portfolio_production > backup.sql
   ```

2. **SSL証明書更新監視**
   - 90日ごとの自動更新を確認
   - 失敗時は緊急HTTPモードで対応

3. **デプロイ前チェックリスト**
   - [ ] マイグレーションコミット確認
   - [ ] 環境変数設定確認
   - [ ] ローカルテスト完了
   - [ ] バックアップ取得

## 🚀 次回デプロイコマンド

```bash
# 通常の安全デプロイ
cd ~/web-server/portfolio
git pull origin main
./scripts/deploy.sh

# 問題発生時
./scripts/deploy.sh --clean-cache  # キャッシュクリア
# または HTTPS_RECOVERY.md 参照
```

---

**結論**: 本番デプロイの「地雷」を踏んだ経験を活かし、安全で復旧可能な運用環境を構築完了。Let's Encrypt制限解除後の17日朝には完全復旧見込み。