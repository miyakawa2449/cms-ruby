# 本番デプロイ完全ガイド - 地雷を踏まないために

## 🎯 このドキュメントの目的

個人で初めてAWS/Dockerデプロイを行う際に遭遇する「地雷」を回避し、安全で確実なデプロイを実現するためのガイドです。

## ⚠️ 絶対に踏んではいけない地雷

### 🚫 地雷1: docker compose down -v
```bash
# ❌ 絶対ダメ（SSL証明書・DB全削除）
docker compose down -v

# ✅ 安全な方法
docker compose down  # -v なし
```

**被害**: SSL証明書削除 → Let's Encryptレート制限 → サイト停止

### 🚫 地雷2: マイグレーション未コミット
```bash
# ❌ ローカルでマイグレーション作成後、即本番デプロイ
rails generate migration ...
# コミット忘れ

# ✅ 正しい手順
rails generate migration ...
git add db/migrate/*
git commit -m "マイグレーション追加"
git push origin main
```

**被害**: 本番で500エラー地獄

### 🚫 地雷3: 環境変数未設定
```bash
# ❌ .env.production 未作成でデプロイ
./scripts/deploy.sh

# ✅ 必須環境変数
POSTGRES_PASSWORD=secure_password
RAILS_MASTER_KEY=your_master_key
APP_HOST=your-domain.com
```

**被害**: URL生成エラー、画像表示不可

## 📋 デプロイ前チェックリスト

### 1. ローカル確認
- [ ] すべてのマイグレーションがコミット済み
- [ ] docker-compose.yml の設定確認
- [ ] nginx設定の妥当性確認
- [ ] 環境変数ファイル準備完了

### 2. 本番環境準備
- [ ] .env.production 作成済み
- [ ] 必要なポート（80/443）開放
- [ ] ドメインのDNS設定完了
- [ ] 既存データのバックアップ取得

### 3. デプロイ実行
- [ ] git pull で最新化
- [ ] deploy.sh の安全オプション理解
- [ ] エラー時の復旧手順確認

## 🔧 主要ファイルの役割と注意点

### 1. deploy.sh
```bash
# 構造
#!/usr/bin/env bash
set -Eeuo pipefail  # エラー時即停止

# 使い方
./scripts/deploy.sh               # 通常（安全）
./scripts/deploy.sh --clean-cache # キャッシュのみ削除
./scripts/deploy.sh --wipe-all    # 危険（要確認入力）
```

**ポイント**:
- デフォルトは全ボリューム保護
- エラー時は自動でログダンプ
- 段階的な起動確認

### 2. docker-compose.production.yml
```yaml
services:
  portfolio-db:      # PostgreSQL
  portfolio-web:     # Rails app
  portfolio-worker:  # Sidekiq/SolidQueue
  nginx:            # リバースプロキシ
  https-portal:     # Let's Encrypt SSL
```

**ポイント**:
- workerコンテナ必須（ActiveStorage用）
- ボリューム設定は慎重に
- ネットワーク分離でセキュリティ確保

### 3. nginx.production.conf
```nginx
# 重要設定
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-Host $http_host;
proxy_set_header X-Forwarded-Proto https;
```

**ポイント**:
- Hostヘッダーは$http_host使用
- HTTPSプロトコル明示必須
- 管理画面パスのリダイレクト設定

### 4. config/environments/production.rb
```ruby
# URL生成設定（必須）
Rails.application.routes.default_url_options[:host] = ENV.fetch("APP_HOST", "domain.com")
Rails.application.routes.default_url_options[:protocol] = "https"

# ActiveStorage対応
config.after_initialize do
  ActiveStorage::Current.url_options = Rails.application.routes.default_url_options
end
```

## 🚨 トラブルシューティング

### 問題1: Let's Encryptレート制限
**症状**: https-portal Restartingループ
```bash
# 緊急対応
docker compose -f docker-compose.production.yml \
               -f docker-compose.production.http.yml up -d
```

### 問題2: 画像が表示されない
**症状**: portfolio-web宛のURL
```bash
# 確認
docker exec portfolio-web bundle exec rails runner \
  'puts Rails.application.routes.default_url_options'
```

### 問題3: 500エラー
**症状**: マイグレーション未実行
```bash
# 手動実行
docker exec portfolio-web bundle exec rails db:migrate
```

## 💡 ベストプラクティス

### 1. デプロイフロー
```bash
# 1. ローカルテスト
docker-compose up
# 動作確認

# 2. コミット・プッシュ
git add -A
git commit -m "本番デプロイ準備"
git push origin main

# 3. 本番デプロイ
ssh production-server
cd project-dir
git pull origin main
./scripts/deploy.sh
```

### 2. バックアップ戦略
```bash
# デプロイ前バックアップ
docker exec db-container pg_dump -U user database > backup_$(date +%Y%m%d).sql

# 定期バックアップ（cron）
0 3 * * * /path/to/backup.sh
```

### 3. 監視ポイント
- SSL証明書の有効期限（90日）
- ディスク使用量（特にログ）
- メモリ使用状況
- エラーログの定期確認

## 📚 参考リンク

- [Docker Compose ドキュメント](https://docs.docker.com/compose/)
- [Let's Encrypt レート制限](https://letsencrypt.org/docs/rate-limits/)
- [Rails Production Guide](https://guides.rubyonrails.org/configuring.html)
- [nginx設定ベストプラクティス](https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/)

## 🎓 学んだ教訓

1. **ボリュームは財産**: 特にSSL証明書とDBは絶対保護
2. **環境変数は生命線**: APP_HOST設定忘れは致命的
3. **ローカルテスト必須**: 本番で初めて試すのは危険
4. **エラーログは友達**: 問題解決の最短経路
5. **バックアップは保険**: 取らずに後悔より取って安心

---

このガイドに従えば、初めてのデプロイでも主要な地雷を回避できます。それでも問題が発生した場合は、落ち着いてログを確認し、このドキュメントのトラブルシューティングセクションを参照してください。

Happy Deploying! 🚀