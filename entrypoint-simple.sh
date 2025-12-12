#!/bin/bash
set -e

# server.pidが存在する場合は削除する（前回の異常終了対策）
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# コマンドを実行
exec "$@"