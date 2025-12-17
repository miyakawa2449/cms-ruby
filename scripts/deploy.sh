#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# Portfolio Rails App - Production Deploy (Safe Version)
# Usage:
# ./scripts/deploy.sh                    # 通常デプロイ（全ボリューム保護）
# ./scripts/deploy.sh --keep-ssl         # SSL証明書を維持したままデプロイ（https-portal継続）
# ./scripts/deploy.sh --keep-ssl --recreate  # コンテナ再作成（https-portal以外）
# ./scripts/deploy.sh --keep-ssl --reset-admin # 管理者ユーザー再作成
# ./scripts/deploy.sh --keep-ssl --reset-db    # DB再作成（危険、要確認）
# ./scripts/deploy.sh --clean-cache      # + キャッシュ削除（tmp/log のみ、安全）
# ./scripts/deploy.sh --wipe-all         # 危険：完全初期化（要明示確認）
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
CLEAN_CACHE=false
WIPE_ALL=false
KEEP_SSL=false
RECREATE=false
RESET_ADMIN=false
RESET_DB=false

for arg in "$@"; do
case "$arg" in
--clean-cache) CLEAN_CACHE=true ;;
--wipe-all) WIPE_ALL=true ;;
--keep-ssl) KEEP_SSL=true ;;
--recreate) RECREATE=true ;;
--reset-admin) RESET_ADMIN=true ;;
--reset-db) RESET_DB=true ;;
-h|--help)
echo "Usage: $0 [OPTIONS]"
echo ""
echo "Basic Options:"
echo "  (none)          通常デプロイ（全コンテナ再起動、全ボリューム保護）"
echo "  --keep-ssl      SSL証明書を維持したままデプロイ（https-portal継続稼働）"
echo "  --clean-cache   キャッシュ削除（tmp/log のみ、安全）"
echo "  --wipe-all      完全初期化（危険、要確認入力）"
echo ""
echo "Advanced Options (use with --keep-ssl):"
echo "  --recreate      コンテナを完全削除して再作成（https-portal以外）"
echo "  --reset-admin   管理者ユーザーを再作成（.env.productionの値を使用）"
echo "  --reset-db      DBを完全リセット（危険、要確認入力）"
echo ""
echo "Examples:"
echo "  $0 --keep-ssl                          # 通常のSSL維持デプロイ"
echo "  $0 --keep-ssl --recreate               # コンテナ再作成"
echo "  $0 --keep-ssl --reset-admin            # 管理者再作成"
echo "  $0 --keep-ssl --recreate --reset-admin # コンテナ再作成 + 管理者再作成"
echo "  $0 --keep-ssl --reset-db               # DB完全リセット（危険）"
exit 0
;;
*)
echo "Unknown argument: $arg"
echo "Run '$0 --help' for usage"
exit 1
;;
esac
done

echo "=========================================="
echo "Portfolio Rails App - Safe Production Deploy"
echo "Project: $PROJECT_NAME"
echo "Env: $ENV_FILE"
echo "Keep SSL: $KEEP_SSL"
echo "Recreate: $RECREATE"
echo "Reset Admin: $RESET_ADMIN"
echo "Reset DB: $RESET_DB"
echo "Clean cache: $CLEAN_CACHE"
echo "Wipe all: $WIPE_ALL"
echo "=========================================="

# ----- helpers -----

dump_status_and_logs() {
echo ""
echo "=== docker compose ps -a ==="
dc ps -a || true

echo ""
echo "=== logs (tail=200) portfolio-web ==="
dc logs --tail=200 --no-color portfolio-web || true

echo ""
echo "=== logs (tail=200) portfolio-worker ==="
dc logs --tail=200 --no-color portfolio-worker || true

echo ""
echo "=== logs (tail=200) portfolio-db ==="
dc logs --tail=200 --no-color portfolio-db || true

echo ""
echo "=== logs (tail=200) nginx ==="
dc logs --tail=200 --no-color nginx || true

echo ""
echo "=== logs (tail=200) https-portal ==="
dc logs --tail=200 --no-color https-portal || true
}

on_error() {
local exit_code=$?
echo ""
echo "❌ ERROR: deploy failed (exit code: $exit_code)"
dump_status_and_logs
exit "$exit_code"
}
trap on_error ERR

require_env_key() {
local key="$1"

local line
line="$(grep -E "^[[:space:]]*$key=" "$ENV_FILE" | tail -n 1 || true)"
if [[ -z "$line" ]]; then
echo "ERROR: $key is missing in $ENV_FILE"
exit 1
fi

if [[ "$line" =~ ^[[:space:]]*$key=$ ]]; then
echo "ERROR: $key is empty in $ENV_FILE"
exit 1
fi
}

get_env_value() {
local key="$1"
local line
line="$(grep -E "^[[:space:]]*$key=" "$ENV_FILE" | tail -n 1 || true)"
if [[ -n "$line" ]]; then
echo "$line" | sed "s/^[[:space:]]*$key=//"
fi
}

wait_for_web_up() {
local retries="${1:-12}"
local interval="${2:-5}"

echo "Waiting for portfolio-web to be Up... (max ${retries} tries)"
for ((i=1; i<=retries; i++)); do
if dc ps | grep -qE 'portfolio-web.*\bUp\b'; then
echo "✅ portfolio-web is Up"
return 0
fi
echo "  ...not ready yet (${i}/${retries}). sleeping ${interval}s"
sleep "$interval"
done

echo "ERROR: portfolio-web did not become Up in time."
dump_status_and_logs
exit 1
}

wait_for_worker_up() {
local retries="${1:-12}"
local interval="${2:-5}"

echo "Waiting for portfolio-worker to be Up... (max ${retries} tries)"
for ((i=1; i<=retries; i++)); do
if dc ps | grep -qE 'portfolio-worker.*\bUp\b'; then
echo "✅ portfolio-worker is Up"
return 0
fi
echo "  ...worker not ready yet (${i}/${retries}). sleeping ${interval}s"
sleep "$interval"
done

echo "ERROR: portfolio-worker did not become Up in time."
dump_status_and_logs
exit 1
}

wait_for_db_up() {
local retries="${1:-12}"
local interval="${2:-5}"

echo "Waiting for portfolio-db to be Up... (max ${retries} tries)"
for ((i=1; i<=retries; i++)); do
if dc ps | grep -qE 'portfolio-db.*\bUp\b'; then
echo "✅ portfolio-db is Up"
sleep 3  # DB接続可能になるまで少し待つ
return 0
fi
echo "  ...db not ready yet (${i}/${retries}). sleeping ${interval}s"
sleep "$interval"
done

echo "ERROR: portfolio-db did not become Up in time."
dump_status_and_logs
exit 1
}

check_db_connection() {
echo "Checking DB connectivity from Rails..."
dc exec -T portfolio-web bundle exec rails runner "puts ActiveRecord::Base.connection.active?"
}

clean_safe_cache() {
echo "🧹 Removing safe cache volumes (tmp/log only)..."
docker volume rm "${PROJECT_NAME}_tmp_data" 2>/dev/null || echo "  tmp_data volume not found (OK)"
docker volume rm "${PROJECT_NAME}_log_data" 2>/dev/null || echo "  log_data volume not found (OK)"
echo "✅ Safe cache cleanup completed"
}

dangerous_wipe_all() {
echo ""
echo "⚠️  DANGER ZONE: Complete volume wipe requested"
echo "This will remove:"
echo "  - 📜 ALL database data (postgres_data)"
echo "  - 🔒 SSL certificates (https_portal_data)"  
echo "  - 📁 All uploaded files (storage_data)"
echo "  - 🧹 All cache data (tmp/log)"
echo ""
echo "This action cannot be undone!"
echo ""
read -p "Type 'WIPE_ALL_VOLUMES' to confirm complete destruction: " CONFIRM
echo ""

if [[ "$CONFIRM" == "WIPE_ALL_VOLUMES" ]]; then
echo "💥 Proceeding with complete volume destruction..."
dc down -v --remove-orphans || true
echo "✅ All volumes have been destroyed"
else
echo "❌ Confirmation failed. Volumes preserved. Exiting."
exit 1
fi
}

# https-portal以外のサービスを停止
stop_services_except_ssl() {
echo "🔒 Keeping https-portal running, stopping other services..."

local services=("portfolio-web" "portfolio-worker" "nginx" "portfolio-db")

for service in "${services[@]}"; do
echo "  Stopping $service..."
dc stop "$service" 2>/dev/null || true
done

echo "✅ Services stopped (https-portal preserved)"
}

# https-portal以外のコンテナを完全削除
remove_containers_except_ssl() {
echo "🗑️  Removing containers (https-portal preserved)..."

local services=("portfolio-web" "portfolio-worker" "nginx" "portfolio-db")

for service in "${services[@]}"; do
echo "  Removing $service..."
dc rm -f "$service" 2>/dev/null || true
done

echo "✅ Containers removed (https-portal preserved)"
}

# https-portal以外のサービスを起動
start_services_except_ssl() {
echo "🚀 Starting services (https-portal already running)..."

local services=("portfolio-db" "portfolio-web" "portfolio-worker" "nginx")

for service in "${services[@]}"; do
echo "  Starting $service..."
dc up -d "$service"
done

echo "✅ Services started"
}

# 管理者ユーザーをリセット
reset_admin_user() {
echo "👤 Resetting admin user..."

local admin_email
local admin_password

admin_email="$(get_env_value 'ADMIN_EMAIL')"
admin_password="$(get_env_value 'ADMIN_PASSWORD')"

if [[ -z "$admin_email" ]] || [[ -z "$admin_password" ]]; then
echo "ERROR: ADMIN_EMAIL and ADMIN_PASSWORD must be set in $ENV_FILE"
echo "Please add:"
echo "  ADMIN_EMAIL=your_email@example.com"
echo "  ADMIN_PASSWORD=your_secure_password"
exit 1
fi

echo "  Email: $admin_email"
echo "  Password: ********"

dc exec -T portfolio-web bundle exec rails runner "
email = '$admin_email'
password = '$admin_password'

# 既存の管理者を削除
AdminUser.destroy_all
puts 'Deleted all existing admin users'

# 新しい管理者を作成
admin = AdminUser.create!(
  email: email,
  password: password,
  password_confirmation: password
)
puts \"Created admin user: #{admin.email}\"
"

echo "✅ Admin user reset completed"
}

# DBをリセット（危険）
dangerous_reset_db() {
echo ""
echo "⚠️  DANGER ZONE: Database reset requested"
echo "This will:"
echo "  - 📜 DROP all tables"
echo "  - 🗑️  DELETE all data (articles, users, uploads metadata, etc.)"
echo "  - 🔄 Re-run migrations"
echo "  - 🌱 Re-run seeds"
echo ""
echo "This action cannot be undone!"
echo ""
read -p "Type 'RESET_DATABASE' to confirm: " CONFIRM
echo ""

if [[ "$CONFIRM" == "RESET_DATABASE" ]]; then
echo "💥 Proceeding with database reset..."

dc exec -T portfolio-web bundle exec rails db:drop db:create db:migrate db:seed

echo "✅ Database has been reset"
else
echo "❌ Confirmation failed. Database preserved."
exit 1
fi
}

# ----- Validation -----

# --reset-admin や --reset-db は --keep-ssl と一緒に使うことを推奨
if [[ "$RESET_ADMIN" == "true" ]] || [[ "$RESET_DB" == "true" ]] || [[ "$RECREATE" == "true" ]]; then
if [[ "$KEEP_SSL" != "true" ]]; then
echo "⚠️  Warning: --recreate, --reset-admin, --reset-db は --keep-ssl と一緒に使うことを推奨します"
echo "   続行しますか？ (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
echo "Aborted."
exit 1
fi
fi
fi

# --wipe-all は他のオプションと排他
if [[ "$WIPE_ALL" == "true" ]]; then
if [[ "$KEEP_SSL" == "true" ]] || [[ "$RECREATE" == "true" ]] || [[ "$RESET_ADMIN" == "true" ]] || [[ "$RESET_DB" == "true" ]]; then
echo "ERROR: --wipe-all cannot be used with other options"
exit 1
fi
fi

# ----- 1. env checks -----

echo "1. Checking environment file..."
if [[ ! -f "$ENV_FILE" ]]; then
echo "ERROR: $ENV_FILE file not found!"
echo "Please create $ENV_FILE with at least:"
echo "  POSTGRES_PASSWORD=your_password"
echo "  RAILS_MASTER_KEY=your_master_key"
echo "  APP_HOST=miyakawa.codes"
echo "  ADMIN_EMAIL=your_email@example.com"
echo "  ADMIN_PASSWORD=your_secure_password"
exit 1
fi

echo "2. Validating required keys in $ENV_FILE..."
require_env_key "POSTGRES_PASSWORD"
require_env_key "RAILS_MASTER_KEY"
require_env_key "APP_HOST"

# --reset-admin の場合は ADMIN_EMAIL と ADMIN_PASSWORD も必須
if [[ "$RESET_ADMIN" == "true" ]]; then
require_env_key "ADMIN_EMAIL"
require_env_key "ADMIN_PASSWORD"
fi

# ----- 3. volume handling -----

if [[ "$WIPE_ALL" == "true" ]]; then
dangerous_wipe_all
elif [[ "$CLEAN_CACHE" == "true" ]]; then
clean_safe_cache
fi

# ----- 4. build -----

echo "3. Building Docker image..."
dc build

# ----- 5. stop existing (safe) -----

echo "4. Stopping existing containers (volumes preserved)..."
if [[ "$KEEP_SSL" == "true" ]]; then
stop_services_except_ssl
if [[ "$RECREATE" == "true" ]]; then
remove_containers_except_ssl
fi
else
dc down --remove-orphans || true
fi

# ----- 6. up -----

echo "5. Starting containers..."
if [[ "$KEEP_SSL" == "true" ]]; then
start_services_except_ssl
else
dc up -d
fi

# ----- 7. verify -----

echo "6. Verifying container startup..."
dc ps -a
wait_for_db_up 12 5
wait_for_web_up 12 5
wait_for_worker_up 12 5

# ----- 8. DB check -----

echo "7. Checking database connection..."
check_db_connection

# ----- 9. DB reset (if requested) -----

if [[ "$RESET_DB" == "true" ]]; then
dangerous_reset_db
else
# 通常のマイグレーション
echo "8. Running migrations..."
dc exec -T portfolio-web bundle exec rails db:migrate
fi

# ----- 10. Admin reset (if requested) -----

if [[ "$RESET_ADMIN" == "true" ]]; then
reset_admin_user
fi

# ----- 11. initial data check -----

echo "9. Checking initial data..."
dc exec -T portfolio-web bundle exec rails runner "
puts 'AdminUsers: ' + AdminUser.count.to_s
puts 'Sections: ' + Section.count.to_s
puts 'Articles: ' + Article.count.to_s
"

# ----- 12. https-portal check -----

echo "10. Checking HTTPS portal status..."
if dc ps | grep -qE 'https-portal.*\bUp\b'; then
echo "✅ https-portal is running"
else
echo "⚠️  https-portal may have issues. Check logs:"
echo "   dc logs https-portal"
fi

# ----- 13. logs -----

echo "11. Showing recent logs..."
dc logs --tail=80 --no-color

echo "=========================================="
echo "✅ Safe deployment completed!"
echo ""
echo "🔗 Access URLs:"
echo "  Frontend: https://miyakawa.codes/"
echo "  Admin:    https://miyakawa.codes/admin-secure-panel-miyakawa2449"
echo ""
echo "🛠️  Useful commands:"
echo "  Check status: dc ps"
echo "  View logs:    dc logs [service]"
echo "  Rails console: dc exec portfolio-web bundle exec rails console"
echo ""
echo "🚨 Emergency HTTP recovery (if HTTPS fails):"
echo "  See HTTPS_RECOVERY.md for instructions"
echo ""
echo "⚠️  Status:"
if [[ "$KEEP_SSL" == "true" ]]; then
echo "  🔒 https_portal: PRESERVED (--keep-ssl)"
fi
if [[ "$RECREATE" == "true" ]]; then
echo "  🔄 Containers:   RECREATED (--recreate)"
fi
if [[ "$RESET_ADMIN" == "true" ]]; then
echo "  👤 Admin user:   RESET (--reset-admin)"
fi
if [[ "$RESET_DB" == "true" ]]; then
echo "  📜 Database:     RESET (--reset-db)"
fi
if [[ "$CLEAN_CACHE" == "true" ]]; then
echo "  🧹 Cache:        CLEANED (--clean-cache)"
fi
echo "  🔒 postgres_data:     PROTECTED"
echo "  🔒 storage_data:      PROTECTED"
echo "=========================================="
