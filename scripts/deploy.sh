#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# Portfolio Rails App - Production Deploy
# Usage:
# ./scripts/deploy.sh         # 通常デプロイ（ボリューム維持）
# ./scripts/deploy.sh --reset # 破壊的：down -v（DB含むボリューム削除）→再構築
# ==========================================

ENV_FILE=".env.production"
PROJECT="portfolio-prod"
COMPOSE=(docker compose --env-file "$ENV_FILE" -p "$PROJECT" -f docker-compose.production.yml)

RESET=false
for arg in "$@"; do
case "$arg" in
--reset) RESET=true ;;
-h|--help)
echo "Usage: $0 [--reset]"
exit 0
;;
*)
echo "Unknown argument: $arg"
echo "Usage: $0 [--reset]"
exit 1
;;
esac
done

echo "=========================================="
echo "Portfolio Rails App - Production Deploy"
echo "Project: $PROJECT"
echo "Env: $ENV_FILE"
echo "Reset volumes: $RESET"
echo "=========================================="

# ----- helpers -----

dump_status_and_logs() {
echo ""
echo "=== docker compose ps -a ==="
"${COMPOSE[@]}" ps -a || true

echo ""
echo "=== logs (tail=200) portfolio-web ==="
"${COMPOSE[@]}" logs --tail=200 --no-color portfolio-web || true

echo ""
echo "=== logs (tail=200) portfolio-worker ==="
"${COMPOSE[@]}" logs --tail=200 --no-color portfolio-worker || true

echo ""
echo "=== logs (tail=200) portfolio-db ==="
"${COMPOSE[@]}" logs --tail=200 --no-color portfolio-db || true

echo ""
echo "=== logs (tail=200) nginx ==="
"${COMPOSE[@]}" logs --tail=200 --no-color nginx || true
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
if "${COMPOSE[@]}" ps | grep -qE 'portfolio-web.*\bUp\b'; then
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
if "${COMPOSE[@]}" ps | grep -qE 'portfolio-worker.*\bUp\b'; then
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
"${COMPOSE[@]}" exec -T portfolio-web bundle exec rails runner "puts ActiveRecord::Base.connection.active?"
}

# ----- 1. env checks -----

echo "1. Checking environment file..."
if [[ ! -f "$ENV_FILE" ]]; then
echo "ERROR: $ENV_FILE file not found!"
echo "Please create $ENV_FILE with at least:"
echo "  POSTGRES_PASSWORD=your_password"
echo "  RAILS_MASTER_KEY=your_master_key"
exit 1
fi

echo "2. Validating required keys in $ENV_FILE..."
require_env_key "POSTGRES_PASSWORD"
require_env_key "RAILS_MASTER_KEY"

# ----- 3. build -----

echo "3. Building Docker image..."
"${COMPOSE[@]}" build

# ----- 4. stop existing -----

echo "4. Stopping existing containers..."
"${COMPOSE[@]}" down || true

# ----- 5. optional reset -----

if [[ "$RESET" == "true" ]]; then
echo "5. Reset requested: removing volumes (DESTRUCTIVE)..."
"${COMPOSE[@]}" down -v || true
else
echo "5. Keeping existing volumes (normal deploy)."
fi

# ----- 6. up -----

echo "6. Starting containers..."
"${COMPOSE[@]}" up -d

# ----- 7. verify -----

echo "7. Verifying container startup..."
"${COMPOSE[@]}" ps -a
wait_for_web_up 12 5
wait_for_worker_up 12 5

# ----- 8. DB check -----

echo "8. Checking database connection..."
check_db_connection

# ----- 9. migrate (recommended for normal ops) -----

echo "9. Running migrations..."
"${COMPOSE[@]}" exec -T portfolio-web bundle exec rails db:migrate

# ----- 10. initial data check (optional) -----

echo "10. Checking initial data..."
"${COMPOSE[@]}" exec -T portfolio-web bundle exec rails runner "
puts 'AdminUsers: ' + AdminUser.count.to_s
puts 'Sections: ' + Section.count.to_s
puts 'Articles: ' + Article.count.to_s
"

# ----- 11. logs -----

echo "11. Showing recent logs..."
"${COMPOSE[@]}" logs --tail=80 --no-color

echo "=========================================="
echo "✅ Deployment completed!"
echo "Access the site via nginx:"
echo "  http://<server-ip-or-domain>/"
echo "Admin panel:"
echo "  http://<server-ip-or-domain>/admin-secure-panel-miyakawa2449"
echo "=========================================="