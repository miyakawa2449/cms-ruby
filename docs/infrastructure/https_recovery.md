# HTTPS障害時の緊急HTTP復旧手順

## 📋 概要

Let's Encryptのレート制限（429エラー）等で`https-portal`が起動しない場合の緊急復旧手順です。

**注意**: この手順は**緊急時のみ**使用してください。通常運用では必ずHTTPS（https-portal）を使用します。

## 🚨 緊急HTTP復旧手順

### 1. 通常構成を停止（ポート競合回避）

```bash
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml down
```

### 2. 緊急HTTPモードで起動

```bash
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml \
  -f docker-compose.production.http.yml \
  up -d --build
```

### 3. 動作確認

```bash
# ローカルから確認
curl -v --max-time 5 http://127.0.0.1/ | head

# または
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml \
  -f docker-compose.production.http.yml \
  ps
```

期待される結果:
- nginx: Up (0.0.0.0:80->80/tcp)
- https-portal: 起動していない

### 4. アクセス確認

ブラウザで以下にアクセス:
- http://miyakawa.codes/ （HTTPのみ）
- http://miyakawa.codes/admin-secure-panel-miyakawa2449

## 🔄 HTTPS通常運用への復帰

### 1. レート制限解除を確認

Let's Encryptのレート制限は通常1時間程度で解除されます。

### 2. HTTPモードを停止

```bash
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml \
  -f docker-compose.production.http.yml \
  down
```

### 3. 通常のHTTPSモードで再起動

```bash
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml \
  up -d
```

### 4. https-portal状態確認

```bash
# ログ確認
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml \
  logs --tail=100 https-portal

# ステータス確認
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml \
  ps
```

## ⚠️ 重要な注意事項

1. **ボリューム保護**
   - 絶対に`down -v`は使用しない（SSL証明書・DBが削除される）
   - `https_portal_data`ボリュームは常に保持

2. **レート制限対策**
   - 証明書の試行錯誤は`STAGE=staging`で実施
   - 本番では証明書再発行を最小限に

3. **セキュリティ**
   - HTTP運用は一時的な緊急対応のみ
   - できるだけ早くHTTPSに戻す

## 📂 ファイル構成

- `docker-compose.production.yml`: 通常のHTTPS構成（メイン）
- `docker-compose.production.http.yml`: 緊急HTTP用差分（https-portal無効化）

## 🛠 トラブルシューティング

### https-portalが「Restarting」ループする場合

```bash
# https-portalのログを確認
docker logs portfolio-prod-https-portal-1 --tail=200

# 429エラーやretry-afterが表示される場合はレート制限
```

### nginxが起動しない場合

```bash
# nginx設定確認
docker compose --env-file .env.production -p portfolio-prod \
  -f docker-compose.production.yml \
  -f docker-compose.production.http.yml \
  exec nginx nginx -t
```

## 📞 サポート

緊急時の対応で不明な点があれば、システム管理者に連絡してください。