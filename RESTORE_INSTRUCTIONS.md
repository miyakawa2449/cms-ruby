# Docker環境 復旧手順書
**作成日**: 2025-12-12  
**状況**: Markdown機能実装後のDocker環境複雑化からの簡素化実施

## 🔄 現在の動作環境に戻す方法

### 手順1: バックアップファイルを復元
```bash
# 現在動作していた設定に戻す
cp entrypoint.sh.backup entrypoint.sh
cp docker-compose.yml.backup docker-compose.yml  
cp Dockerfile.dev.simple.backup Dockerfile.dev.simple
```

### 手順2: Docker環境再構築
```bash
docker-compose down
docker-compose up --build -d
```

### 手順3: 動作確認
```bash
# サーバー応答確認
curl -I http://localhost:3000/

# Markdown機能確認
docker-compose exec web bash -c "rails runner 'puts ApplicationHelper.instance_methods.include?(:markdown)'"
```

## 📋 バックアップ済み設定の特徴
- **entrypoint.sh**: pg_isready使用のデータベース待機ロジック
- **docker-compose.yml**: health check依存の起動順序制御
- **Dockerfile.dev.simple**: 複数エントリーポイント対応

## ✅ 動作確認済み機能
- HTTP 200応答
- Markdown表示機能
- ブログサムネイル表示
- セクション管理
- API機能

## 🚨 緊急時の連絡先
問題発生時は、この手順書に従って元の設定に復旧してください。