# Active Storage URL修正指示書

## 問題の概要

Active Storageでアップロードした画像（Favicon、Logo等）のURLが、本番環境で`portfolio-web`（Dockerコンテナ名）にリダイレクトされ、`ERR_NAME_NOT_RESOLVED`エラーが発生している。

### 症状
- HTMLソースでは正しいURL（`https://miyakawa.codes/rails/active_storage/blobs/redirect/...`）が生成される
- しかしリダイレクト先が`portfolio-web/rails/active_storage/disk/...`になってしまう
- ブラウザが`portfolio-web`を解決できずエラーになる

### 原因
Docker環境でnginxの背後にRailsがある場合、Active StorageのDisk Serviceがリダイレクト時にリクエストのHostヘッダー（内部ネットワーク名）を使用してしまう。

---

## 事前準備: .env.production の設定

修正作業の前に、`.env.production` に管理者ユーザーの設定を追加してください。

### 追加する環境変数

```bash
# ===========================================
# 管理者ユーザー設定
# ===========================================
ADMIN_EMAIL=your_email@example.com
ADMIN_PASSWORD=your_secure_password
```

### .env.production の完成形（例）

```bash
# ===========================================
# Database
# ===========================================
POSTGRES_PASSWORD=your_db_password

# ===========================================
# Rails
# ===========================================
RAILS_MASTER_KEY=your_master_key
RAILS_ENV=production

# ===========================================
# Application
# ===========================================
APP_HOST=miyakawa.codes
FORCE_SSL=true

# ===========================================
# 管理者ユーザー設定
# ===========================================
ADMIN_EMAIL=your_email@example.com
ADMIN_PASSWORD=your_secure_password
```

**注意**: 
- `ADMIN_EMAIL` と `ADMIN_PASSWORD` は `--reset-admin` オプション使用時に必須です
- パスワードは十分に強力なものを設定してください
- このファイルはGitにコミットしないでください（.gitignoreに含まれているはず）

---

## 修正作業

### 1. config/environments/production.rb の修正

**場所**: 25行目付近、`config.active_storage.service = :local` の直後

**変更内容**: 以下の設定を追加

```ruby
# Store uploaded files on the local file system (see config/storage.yml for options).
config.active_storage.service = :local

# プロキシモードを使用してリダイレクト時のホスト問題を回避
# これにより、ブラウザが直接ディスクサービスURLにアクセスする代わりに
# Railsがファイルをプロキシして配信する
config.active_storage.resolve_model_to_route = :rails_storage_proxy
```

---

### 2. 新規ファイル作成: config/initializers/active_storage_url_options.rb

**内容**: 以下の内容で新規ファイルを作成

```ruby
# frozen_string_literal: true

# Active Storage URL Options Configuration
# 
# このイニシャライザは、Active Storage がファイルURLを生成する際に
# 正しいホスト名とプロトコルを使用することを保証します。
# 
# 問題: Docker環境でリバースプロキシ（nginx）の背後にRailsがある場合、
# Active Storage のディスクサービスがDockerコンテナ名（例：portfolio-web）を
# ホストとして使用してしまう。
#
# 解決策: 本番環境では明示的にホストとプロトコルを設定する。

Rails.application.config.after_initialize do
  if Rails.env.production?
    # 環境変数またはデフォルト値からURLオプションを設定
    url_options = {
      host: ENV.fetch("APP_HOST", "miyakawa.codes"),
      protocol: "https"
    }
    
    # Routes のデフォルトURLオプションを設定
    Rails.application.routes.default_url_options = url_options
    
    # ActiveStorage::Current のURLオプションを設定
    ActiveStorage::Current.url_options = url_options
    
    Rails.logger.info "Active Storage URL options configured: #{url_options}"
  end
end

# ミドルウェアを追加して、各リクエストでActiveStorage::Current.url_optionsを設定
# これにより、リダイレクトURL生成時に正しいホストが使用される
class ActiveStorageUrlOptionsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if Rails.env.production?
      # 明示的にホストを設定（X-Forwarded-Host があればそちらを優先）
      forwarded_host = env['HTTP_X_FORWARDED_HOST']
      original_host = env['HTTP_HOST']
      
      # X-Forwarded-Proto または HTTPS 環境変数からプロトコルを決定
      forwarded_proto = env['HTTP_X_FORWARDED_PROTO']
      is_https = forwarded_proto == 'https' || env['HTTPS'] == 'on'
      
      # 信頼できるホスト名を使用（環境変数で指定されたものを優先）
      trusted_host = ENV.fetch("APP_HOST", "miyakawa.codes")
      
      ActiveStorage::Current.url_options = {
        host: trusted_host,
        protocol: "https"
      }
    end
    
    @app.call(env)
  end
end

# ミドルウェアを登録
Rails.application.config.middleware.insert_before 0, ActiveStorageUrlOptionsMiddleware
```

---

### 3. nginx.production.conf の修正

**変更箇所1**: `location /` ブロック内のヘッダー設定

**変更前**:
```nginx
location / {
    proxy_pass http://portfolio-web:80;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-Proto https;
    proxy_redirect off;
    ...
}
```

**変更後**:
```nginx
location / {
    proxy_pass http://portfolio-web:80;
    proxy_set_header Host miyakawa.codes;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host miyakawa.codes;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Port 443;
    proxy_redirect off;
    ...
}
```

**変更箇所2**: 静的ファイルのlocationブロック

**変更前**:
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    proxy_pass http://portfolio-web:80;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

**変更後**:
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    proxy_pass http://portfolio-web:80;
    proxy_set_header Host miyakawa.codes;
    proxy_set_header X-Forwarded-Host miyakawa.codes;
    proxy_set_header X-Forwarded-Proto https;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

**変更箇所3**: ヘルスチェックのlocationブロック

**変更前**:
```nginx
location /health {
    access_log off;
    proxy_pass http://portfolio-web:80/health;
}
```

**変更後**:
```nginx
location /health {
    access_log off;
    proxy_pass http://portfolio-web:80/health;
    proxy_set_header Host miyakawa.codes;
    proxy_set_header X-Forwarded-Host miyakawa.codes;
    proxy_set_header X-Forwarded-Proto https;
}
```

---

## デプロイ手順

修正完了後、`./scripts/deploy.sh` を使用してデプロイします。

### 通常デプロイ（全コンテナ再起動）

```bash
./scripts/deploy.sh
```

### SSL証明書を維持したままデプロイ（推奨）

`https-portal` コンテナを停止せずにデプロイします。SSL証明書の再取得を避けられます。

```bash
./scripts/deploy.sh --keep-ssl
```

### コンテナを完全に再作成する場合

```bash
./scripts/deploy.sh --keep-ssl --recreate
```

### 管理者ユーザーを再作成する場合

`.env.production` の `ADMIN_EMAIL` と `ADMIN_PASSWORD` の値で管理者を再作成します。

```bash
./scripts/deploy.sh --keep-ssl --reset-admin
```

### コンテナ再作成 + 管理者再作成（フル再構築）

```bash
./scripts/deploy.sh --keep-ssl --recreate --reset-admin
```

### キャッシュクリア付きデプロイ

```bash
./scripts/deploy.sh --keep-ssl --clean-cache
```

### deploy.sh のオプション一覧

| オプション | 説明 |
|-----------|------|
| (なし) | 通常デプロイ（全コンテナ再起動、全ボリューム保護）|
| `--keep-ssl` | https-portalを継続稼働させたままデプロイ |
| `--recreate` | コンテナを完全削除して再作成（https-portal以外）|
| `--reset-admin` | 管理者ユーザーを再作成（.env.productionの値を使用）|
| `--reset-db` | DBを完全リセット（危険、要確認入力）|
| `--clean-cache` | tmp/logキャッシュを削除（安全）|
| `--wipe-all` | 完全初期化（危険、要確認入力）|

### オプションの組み合わせ例

```bash
# 推奨：SSL維持でデプロイ
./scripts/deploy.sh --keep-ssl

# コンテナ問題がある場合：再作成
./scripts/deploy.sh --keep-ssl --recreate

# 管理者ログインできない場合：管理者再作成
./scripts/deploy.sh --keep-ssl --reset-admin

# 完全にやり直したい場合（データは保持）
./scripts/deploy.sh --keep-ssl --recreate --reset-admin --clean-cache

# DBも含めて完全リセット（危険：データ全削除）
./scripts/deploy.sh --keep-ssl --reset-db
```

---

## 動作確認

1. https://miyakawa.codes/ にアクセス
2. ブラウザの開発者ツール（F12）でConsoleを確認
3. `ERR_NAME_NOT_RESOLVED` エラーが出ないことを確認
4. 管理画面でFavicon/Logoが正しく表示されることを確認

---

## 修正の技術的説明

### なぜプロキシモードを使用するのか

`config.active_storage.resolve_model_to_route = :rails_storage_proxy` を設定すると:

- **従来（redirect）**: ブラウザ → Rails（302リダイレクト）→ ブラウザ → Disk Service URL
- **プロキシモード**: ブラウザ → Rails（ファイルを直接返す）

プロキシモードでは、Railsがファイルの内容を直接返すため、リダイレクト時のホスト名問題が発生しない。

### nginxのHost固定の理由

`$http_host`（動的）を`miyakawa.codes`（固定）に変更することで、Dockerネットワーク内部のリクエストでも常に正しいホスト名がRailsに伝わる。

---

## 追加修正: scripts/deploy.sh

### 変更概要

以下のオプションを追加し、`https-portal` コンテナを停止せずに柔軟なデプロイができるようにする：

- `--keep-ssl`: https-portalを維持したままデプロイ
- `--recreate`: コンテナを完全削除して再作成
- `--reset-admin`: 管理者ユーザーを再作成
- `--reset-db`: DBを完全リセット

### 完成した deploy.sh の主要部分

deploy.sh は全体を置き換えるため、zipファイルに含まれる `scripts/deploy.sh` をそのまま使用してください。

### 主な追加機能

#### 1. 管理者リセット機能

```bash
reset_admin_user() {
  # .env.production から ADMIN_EMAIL と ADMIN_PASSWORD を読み込み
  # 既存の AdminUser を全削除
  # 新しい管理者を作成
}
```

#### 2. コンテナ再作成機能

```bash
remove_containers_except_ssl() {
  # https-portal以外のコンテナを完全削除
  # ボリュームは保持
}
```

#### 3. DBリセット機能（危険）

```bash
dangerous_reset_db() {
  # 確認入力を求める
  # db:drop db:create db:migrate db:seed を実行
}
```

### ヘルプメッセージ

```bash
$ ./scripts/deploy.sh --help

Usage: ./scripts/deploy.sh [OPTIONS]

Basic Options:
  (none)          通常デプロイ（全コンテナ再起動、全ボリューム保護）
  --keep-ssl      SSL証明書を維持したままデプロイ（https-portal継続稼働）
  --clean-cache   キャッシュ削除（tmp/log のみ、安全）
  --wipe-all      完全初期化（危険、要確認入力）

Advanced Options (use with --keep-ssl):
  --recreate      コンテナを完全削除して再作成（https-portal以外）
  --reset-admin   管理者ユーザーを再作成（.env.productionの値を使用）
  --reset-db      DBを完全リセット（危険、要確認入力）

Examples:
  ./scripts/deploy.sh --keep-ssl                          # 通常のSSL維持デプロイ
  ./scripts/deploy.sh --keep-ssl --recreate               # コンテナ再作成
  ./scripts/deploy.sh --keep-ssl --reset-admin            # 管理者再作成
  ./scripts/deploy.sh --keep-ssl --recreate --reset-admin # コンテナ再作成 + 管理者再作成
  ./scripts/deploy.sh --keep-ssl --reset-db               # DB完全リセット（危険）
```
