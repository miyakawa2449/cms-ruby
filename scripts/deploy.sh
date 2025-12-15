#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# Portfolio Rails App - Production Deploy (Safe Version)
# Usage:
# ./scripts/deploy.sh                    # 通常デプロイ（全ボリューム保護）
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

for arg in "$@"; do
case "$arg" in
--clean-cache) CLEAN_CACHE=true ;;
--wipe-all) WIPE_ALL=true ;;
-h|--help)
echo "Usage: $0 [OPTIONS]"
echo "Options:"
echo "  (none)        通常デプロイ（全ボリューム保護）"
echo "  --clean-cache キャッシュ削除（tmp/log のみ、安全）"
echo "  --wipe-all    完全初期化（危険、要確認入力）"
exit 0
;;
*)
echo "Unknown argument: $arg"
echo "Usage: $0 [--clean-cache|--wipe-all]"
exit 1
;;
esac
done

echo "=========================================="
echo "Portfolio Rails App - Safe Production Deploy"
echo "Project: $PROJECT_NAME"
echo "Env: $ENV_FILE"
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

# コメント/空行除外しつつ key= を探す。値が空もNG。
local line
line="$(grep -E "^[[:space:]]*$key=" "$ENV_FILE" | tail -n 1 || true)"
if [[ -z "$line" ]]; then
echo "ERROR: $key is missing in $ENV_FILE"
exit 1
fi

# key= の後ろが空ならNG
if [[ "$line" =~ ^[[:space:]]*$key=$ ]]; then
echo "ERROR: $key is empty in $ENV_FILE"
exit 1
fi
}

wait_for_web_up() {
local retries="${1:-12}"  # 12 * 5s = 60s
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
local retries="${1:-12}"  # 12 * 5s = 60s
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

check_db_connection() {
echo "Checking DB connectivity from Rails..."

# true が出ればOK。例外なら trap で落ちる。
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

# ----- 1. env checks -----

echo "1. Checking environment file..."
if [[ ! -f "$ENV_FILE" ]]; then
echo "ERROR: $ENV_FILE file not found!"
echo "Please create $ENV_FILE with at least:"
echo "  POSTGRES_PASSWORD=your_password"
echo "  RAILS_MASTER_KEY=your_master_key"
echo "  APP_HOST=miyakawa.codes"
exit 1
fi

echo "2. Validating required keys in $ENV_FILE..."
require_env_key "POSTGRES_PASSWORD"
require_env_key "RAILS_MASTER_KEY"
require_env_key "APP_HOST"

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
dc down --remove-orphans || true

# ----- 6. up -----

echo "5. Starting containers..."
dc up -d

# ----- 7. verify -----

echo "6. Verifying container startup..."
dc ps -a
wait_for_web_up 12 5
wait_for_worker_up 12 5

# ----- 8. DB check -----

echo "7. Checking database connection..."
check_db_connection

# ----- 9. migrate (recommended for normal ops) -----

echo "8. Running migrations..."
dc exec -T portfolio-web bundle exec rails db:migrate

# ----- 10. initial data check (optional) -----

echo "9. Checking initial data..."
dc exec -T portfolio-web bundle exec rails runner "
puts 'AdminUsers: ' + AdminUser.count.to_s
puts 'Sections: ' + Section.count.to_s
puts 'Articles: ' + Article.count.to_s
"

# ----- 11. https-portal check -----

echo "10. Checking HTTPS portal status..."
if dc ps | grep -qE 'https-portal.*\bUp\b'; then
echo "✅ https-portal is running"
else
echo "⚠️  https-portal may have issues. Check logs:"
echo "   dc logs https-portal"
fi

# ----- 12. logs -----

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
echo "⚠️  Volume protection status:"
echo "  🔒 postgres_data:     PROTECTED"
echo "  🔒 https_portal_data: PROTECTED" 
echo "  🔒 storage_data:      PROTECTED"
if [[ "$CLEAN_CACHE" == "true" ]]; then
echo "  🧹 tmp/log data:      CLEANED"
else
echo "  📦 tmp/log data:      PRESERVED"
fi
echo "=========================================="