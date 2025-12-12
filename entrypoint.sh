#!/bin/bash
set -e

# server.pidが存在する場合は削除する（前回の異常終了対策）
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# Docker Composeのhealth checkに依存関係を任せる
# シンプルにコマンドを実行
exec "$@"