# セキュリティガイド

## 概要
このドキュメントは、ポートフォリオCMSのセキュリティ機能と運用指針をまとめたものです。

## セキュリティヘッダー

### Content Security Policy (CSP)
- 設定ファイル: `config/initializers/content_security_policy.rb`
- 目的: XSS対策、外部リソース制御
- 本番環境は厳格、開発/テストは動作優先で緩和

### X-Frame-Options
- 値: `SAMEORIGIN`
- クリックジャッキング対策

### X-Content-Type-Options
- 値: `nosniff`
- MIMEスニッフィング対策

### Strict-Transport-Security (HSTS)
- 本番環境のみ有効
- `ENABLE_HSTS=true` の場合に有効化

### Referrer-Policy
- 値: `strict-origin-when-cross-origin`

### Permissions-Policy
- 値: `geolocation=(), microphone=(), camera=()`

## レート制限（Rack::Attack）

設定ファイル: `config/initializers/rack_attack.rb`

- ログイン試行: 5回/20秒
- パスワードリセット: 5回/1時間
- API（未認証）: 60回/分
- API（認証済み）: 300回/分
- 管理画面（未認証）: 10回/分
- お問い合わせフォーム: 5回/1時間

### 管理者ホワイトリスト
- `ADMIN_WHITELIST_IPS` に IP をカンマ区切りで指定
- 指定IPはレート制限を受けません

## セキュリティログ（SecurityLogger）

ログ例:

```json
{
  "timestamp": "2026-01-22T10:00:00+09:00",
  "environment": "production",
  "event": "login_failure",
  "email": "admin@example.com",
  "ip": "192.168.1.1",
  "user_agent": "Mozilla/5.0..."
}
```

対象イベント:
- ログイン成功/失敗
- ログアウト
- アカウントロック/アンロック
- 管理画面への不正アクセス試行
- レート制限ブロック

## 入力検証・サニタイゼーション

### Markdown
- `app/helpers/markdown_helper.rb` でサニタイズを実施
- script タグや危険属性は除去

### ファイルアップロード
- `MediaValidatable` により MIME タイプ/サイズ/内容を検証
- 許可形式: JPEG, PNG, GIF, WebP
- 最大サイズ: 10MB

## 環境変数

```bash
ADMIN_PATH=admin-secure-panel-miyakawa2449
REDIS_URL=redis://localhost:6379/1
ADMIN_WHITELIST_IPS=192.168.1.1,192.168.1.2
ENABLE_HSTS=true
HSTS_MAX_AGE=31536000
```

## トラブルシューティング

### CSP 違反が発生する
- 必要な外部ドメインが許可されているか確認
- インラインスクリプトには nonce を付与

### レート制限に引っかかる
- `Retry-After` ヘッダーに従って待機
- 管理者IPは `ADMIN_WHITELIST_IPS` でホワイトリスト化

### セキュリティログが出ない
- `SecurityLogger` が呼ばれているか確認
- ログレベルが `info` 以上であることを確認
