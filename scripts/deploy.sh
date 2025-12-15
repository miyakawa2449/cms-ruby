#!/bin/bash
set -e

# デプロイスクリプト - 本番環境への完全デプロイ

echo "=========================================="
echo "Portfolio Rails App - Production Deploy"
echo "=========================================="

# 1. 環境変数チェック
echo "1. Checking environment variables..."
if [ ! -f .env.production ]; then
    echo "ERROR: .env.production file not found!"
    echo "Please create .env.production with:"
    echo "  POSTGRES_PASSWORD=your_password"
    echo "  RAILS_MASTER_KEY=your_master_key"
    exit 1
fi

# 2. 環境変数を読み込み
echo "2. Loading environment variables..."
set -a
source .env.production
set +a

# 3. Dockerビルド
echo "3. Building Docker image..."
docker-compose -p portfolio-prod -f docker-compose.production.yml build

# 4. 既存コンテナ停止（存在する場合）
echo "4. Stopping existing containers..."
docker-compose -p portfolio-prod -f docker-compose.production.yml down || true

# 5. ボリュームクリーンアップ（オプション）
read -p "Clean up existing volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose -p portfolio-prod -f docker-compose.production.yml down -v
fi

# 6. コンテナ起動
echo "6. Starting containers..."
docker-compose -p portfolio-prod -f docker-compose.production.yml up -d

# 7. ヘルスチェック待機
echo "7. Waiting for services to be ready..."
sleep 10

# 8. データベース状態確認
echo "8. Checking database status..."
docker-compose -p portfolio-prod -f docker-compose.production.yml exec portfolio-web rails db:status

# 9. 初期データ確認
echo "9. Checking initial data..."
docker-compose -p portfolio-prod -f docker-compose.production.yml exec portfolio-web rails runner "
  puts 'AdminUsers: ' + AdminUser.count.to_s
  puts 'Sections: ' + Section.count.to_s
  puts 'Articles: ' + Article.count.to_s
"

# 10. ログ表示
echo "10. Showing recent logs..."
docker-compose -p portfolio-prod -f docker-compose.production.yml logs --tail=50

echo "=========================================="
echo "Deployment completed!"
echo "Access the site at: http://localhost"
echo "Admin panel: http://localhost/admin-secure-panel-miyakawa2449"
echo "=========================================="