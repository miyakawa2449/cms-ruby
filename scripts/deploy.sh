#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# Portfolio Rails App - Production Deploy (Enhanced Version)
# Usage:
# ./scripts/deploy.sh                              # 通常デプロイ（全コンテナ再起動、全ボリューム保護）
# ./scripts/deploy.sh --keep-ssl                   # SSL証明書を維持したままデプロイ
# ./scripts/deploy.sh --keep-ssl --recreate        # コンテナ再作成（https-portal以外）
# ./scripts/deploy.sh --keep-ssl --reset-admin     # 管理者ユーザー再作成
# ./scripts/deploy.sh --keep-ssl --reset-db        # DB完全リセット（危険）
# ./scripts/deploy.sh --clean-cache                # キャッシュ削除（安全）
# ./scripts/deploy.sh --wipe-all                   # 危険：完全初期化
# ==========================================

# ----- 設定変数 -----
ENV_FILE=".env.production"
PROJECT_NAME="portfolio-prod"
COMPOSE_FILE="docker-compose.production.yml"

# Docker Compose コマンド短縮
dc() {
  docker compose --env-file "$ENV_FILE" -p "$PROJECT_NAME" -f "$COMPOSE_FILE" "$@"
}

# ----- オプション解析 -----
KEEP_SSL=false
RECREATE=false
RESET_ADMIN=false
RESET_DB=false
CLEAN_CACHE=false
WIPE_ALL=false

for arg in "$@"; do
case "$arg" in
--keep-ssl) KEEP_SSL=true ;;
--recreate) RECREATE=true ;;
--reset-admin) RESET_ADMIN=true ;;
--reset-db) RESET_DB=true ;;
--clean-cache) CLEAN_CACHE=true ;;
--wipe-all) WIPE_ALL=true ;;
-h|--help)
cat << EOF
Usage: $0 [OPTIONS]

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
  $0 --keep-ssl                          # 通常のSSL維持デプロイ
  $0 --keep-ssl --recreate               # コンテナ再作成
  $0 --keep-ssl --reset-admin            # 管理者再作成
  $0 --keep-ssl --recreate --reset-admin # コンテナ再作成 + 管理者再作成
  $0 --keep-ssl --reset-db               # DB完全リセット（危険）
EOF
exit 0
;;
*)
echo "Unknown argument: $arg"
echo "Use --help for usage information"
exit 1
;;
esac
done

echo "=========================================="
echo "Portfolio Rails App - Enhanced Production Deploy"
echo "Project: $PROJECT_NAME"
echo "Env: $ENV_FILE"
echo "Keep SSL: $KEEP_SSL"
echo "Recreate: $RECREATE"
echo "Reset Admin: $RESET_ADMIN"
echo "Reset DB: $RESET_DB"
echo "Clean cache: $CLEAN_CACHE"
echo "=========================================="
echo

# ----- 環境ファイルチェック -----
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found!"
  echo "Please copy .env.production.example to .env.production and configure it."
  exit 1
fi

# ----- 管理者リセット用環境変数チェック -----
if [ "$RESET_ADMIN" = true ]; then
  if ! grep -q "ADMIN_EMAIL" "$ENV_FILE" || ! grep -q "ADMIN_PASSWORD" "$ENV_FILE"; then
    echo "Error: ADMIN_EMAIL and ADMIN_PASSWORD must be set in $ENV_FILE for --reset-admin"
    echo "Please add these to your .env.production file:"
    echo "ADMIN_EMAIL=your_email@example.com"
    echo "ADMIN_PASSWORD=your_secure_password"
    exit 1
  fi
fi

# ----- ヘルパー関数 -----

# 管理者ユーザーリセット関数
reset_admin_user() {
  echo "→ Resetting admin user..."
  
  # .env.production から値を読み込み
  source "$ENV_FILE"
  
  if [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "Error: ADMIN_EMAIL or ADMIN_PASSWORD not found in $ENV_FILE"
    return 1
  fi
  
  dc exec -T portfolio-web rails runner "
    AdminUser.destroy_all
    AdminUser.create!(
      email: ENV['ADMIN_EMAIL'],
      password: ENV['ADMIN_PASSWORD'],
      password_confirmation: ENV['ADMIN_PASSWORD']
    )
    puts 'Admin user created successfully!'
  "
}

# コンテナ削除関数（SSL以外）
remove_containers_except_ssl() {
  echo "→ Removing containers (except https-portal)..."
  
  # https-portal以外のコンテナを停止・削除
  local containers=$(docker ps -a --filter "label=com.docker.compose.project=$PROJECT_NAME" --format "{{.Names}}" | grep -v "https-portal" || true)
  
  if [ -n "$containers" ]; then
    echo "$containers" | xargs -r docker stop
    echo "$containers" | xargs -r docker rm
  fi
}

# DB完全リセット関数
dangerous_reset_db() {
  echo "!!! WARNING !!!"
  echo "This will DELETE ALL DATA in the database!"
  echo "Type 'reset-database-production' to confirm:"
  read -r confirmation
  
  if [ "$confirmation" != "reset-database-production" ]; then
    echo "Cancelled."
    return 1
  fi
  
  echo "→ Resetting database..."
  dc exec -T portfolio-web rails db:drop db:create db:migrate db:seed
}

# 完全削除関数（危険）
dangerous_wipe_all() {
  echo "!!! DANGER !!!"
  echo "This will DELETE ALL DATA including:"
  echo "- Database data"
  echo "- Redis data"
  echo "- SSL certificates"
  echo "- All uploads and media"
  echo
  echo "Type 'wipe-all-production-data' to confirm:"
  read -r confirmation
  
  if [ "$confirmation" != "wipe-all-production-data" ]; then
    echo "Cancelled."
    exit 0
  fi
  
  echo "→ Stopping and removing all containers..."
  dc down -v
  
  echo "→ Removing all volumes..."
  docker volume ls --filter "label=com.docker.compose.project=$PROJECT_NAME" -q | xargs -r docker volume rm || true
  
  echo "→ All data wiped!"
}

# ----- メインロジック -----

# 完全削除モード
if [ "$WIPE_ALL" = true ]; then
  dangerous_wipe_all
  echo "→ Please run deploy again to recreate everything."
  exit 0
fi

# 通常のデプロイフロー
echo "→ Starting deployment..."

# 1. Dockerビルド
echo "→ Building Docker images..."
dc build

# 2. コンテナ管理
if [ "$KEEP_SSL" = true ]; then
  echo "→ Keeping SSL certificate (https-portal running)..."
  
  if [ "$RECREATE" = true ]; then
    # https-portal以外を削除して再作成
    remove_containers_except_ssl
  else
    # https-portal以外を再起動
    dc stop portfolio-web portfolio-db portfolio-redis sidekiq
  fi
else
  # 全コンテナを停止（ボリュームは保持）
  echo "→ Stopping all containers..."
  dc down
fi

# 3. キャッシュクリア（オプション）
if [ "$CLEAN_CACHE" = true ]; then
  echo "→ Cleaning cache directories..."
  rm -rf ./tmp/cache/* || true
  rm -rf ./log/* || true
  echo "  Cache cleared."
fi

# 4. コンテナ起動
echo "→ Starting containers..."
if [ "$KEEP_SSL" = true ]; then
  # https-portal以外を起動
  dc up -d portfolio-db portfolio-redis
  sleep 5  # DBの起動待ち
  dc up -d portfolio-web sidekiq
else
  # 全コンテナ起動
  dc up -d
fi

# 5. DB起動待機
echo "→ Waiting for database..."
sleep 10

# 6. DBセットアップ/リセット
if [ "$RESET_DB" = true ]; then
  dangerous_reset_db
else
  # 通常のマイグレーション
  echo "→ Running database migrations..."
  dc exec -T portfolio-web rails db:migrate
fi

# 7. 管理者リセット（オプション）
if [ "$RESET_ADMIN" = true ]; then
  reset_admin_user
fi

# 8. アセットコンパイル
echo "→ Compiling assets..."
dc exec -T portfolio-web rails assets:precompile

# 9. 最終チェック
echo "→ Checking application status..."
dc ps
echo
dc exec -T portfolio-web rails runner "puts 'Rails: OK'"
echo

echo "=========================================="
echo "Deployment complete!"
echo
echo "Access the site at: https://$(grep APP_HOST "$ENV_FILE" | cut -d'=' -f2 || echo 'miyakawa.codes')/"
echo "Admin panel: https://$(grep APP_HOST "$ENV_FILE" | cut -d'=' -f2 || echo 'miyakawa.codes')/admin-secure-panel-miyakawa2449"
echo
if [ "$KEEP_SSL" = true ]; then
  echo "Note: SSL certificate was preserved during deployment."
fi
echo "=========================================="