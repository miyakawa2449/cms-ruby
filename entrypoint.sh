#!/bin/bash
set -e

# server.pidが存在する場合は削除する（前回の異常終了対策）
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# 以下のコマンドはデータベース待機をスキップ
if [[ "$1" == "rails" && "$2" == "new" ]]; then
  exec "$@"
  exit 0
fi

if [[ "$1" == "bundle" && "$2" == "install" ]]; then
  exec "$@"
  exit 0
fi

# データベースの準備ができるまで待機
if [ -n "$DATABASE_URL" ]; then
  # DATABASE_URLから情報を抽出
  DB_HOST=$(echo $DATABASE_URL | sed -E 's/.*@([^:]+):.*/\1/')
  DB_USER=$(echo $DATABASE_URL | sed -E 's/.*:\/\/([^:]+):.*/\1/')
  DB_PASS=$(echo $DATABASE_URL | sed -E 's/.*:\/\/[^:]+:([^@]+)@.*/\1/')
  
  until PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -c '\q' 2>/dev/null; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
  done
else
  # 環境変数が設定されていない場合はスキップ
  >&2 echo "DATABASE_URL not set, skipping database check"
fi

>&2 echo "Postgres is up - executing command"

# コマンドを実行
exec "$@"