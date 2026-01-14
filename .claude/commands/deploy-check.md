---
description: 本番デプロイ前の安全チェック
---

本番デプロイ前に以下のチェックを実行してください：

## 1. Git状態確認
```bash
git status
git log --oneline -5
```

- [ ] 未コミットの変更がないこと
- [ ] 適切なコミットメッセージがあること

## 2. テスト実行（該当する場合）
```bash
docker-compose exec web rails test
# または
docker-compose exec web rspec
```

- [ ] 全テストがパスすること

## 3. セキュリティチェック
```bash
# 機密情報が含まれていないか確認
git diff HEAD~1 --name-only | xargs grep -l -E "(password|secret|api_key|token)" 2>/dev/null || echo "OK: No secrets found"
```

- [ ] 機密情報がハードコードされていないこと

## 4. マイグレーション確認
```bash
docker-compose exec web rails db:migrate:status
```

- [ ] 未実行のマイグレーションがないこと（あれば本番で実行が必要）

## 5. 環境変数確認
本番環境で必要な環境変数：
- `RAILS_MASTER_KEY`
- `DATABASE_URL`
- `REDIS_URL`
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`

## 6. デプロイ手順確認
```bash
# 本番サーバーへのデプロイ
./scripts/deploy.sh --keep-ssl
```

## チェック結果サマリー
上記のチェック結果をまとめて報告してください。問題がある場合は警告を表示。
