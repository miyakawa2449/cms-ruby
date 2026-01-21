# Phase 6 セキュリティ強化 - 実装レポート

作成日: 2026-01-22
担当: Codex

---

## 1. 実装サマリー

### 実装した機能
1. **セキュリティヘッダーの最適化**
   - CSPをRails設定で統一（nonce対応・環境別緩和）
   - X-Frame-Options / X-Content-Type-Options / Referrer-Policy / Permissions-Policy を追加
   - HSTS（本番のみ）を設定可能に

2. **SecurityLogger サービスの追加**
   - ログイン成功/失敗、ログアウト、アカウントロック/アンロック、不正アクセス、レート制限ブロックを構造化ログで記録

3. **Rack::Attack 最適化**
   - 本番はRedisキャッシュ、開発/テストはMemoryStore
   - 管理者IPホワイトリスト
   - API認証/未認証のレート制限を分離
   - 管理画面の不正アクセス試行を制限

4. **入力検証の強化**
   - Markdown 出力をサニタイズ
   - メディアアップロードのMIME/サイズ/内容検証を追加
   - インラインJS属性を削除し、CSP整合性を改善

### 変更したファイル（抜粋）
- `config/initializers/content_security_policy.rb`
- `config/initializers/security_headers.rb`
- `config/initializers/rack_attack.rb`
- `config/initializers/devise.rb`
- `app/services/security_logger.rb`
- `app/models/concerns/media_validatable.rb`
- `app/helpers/markdown_helper.rb`
- `app/controllers/admin/base_controller.rb`
- `app/controllers/application_controller.rb`
- `app/helpers/gtm_helper.rb`
- `app/javascript/controllers/clipboard_controller.js`
- `app/views/shared/_ogp_card.html.erb`
- `app/views/my_story/index.html.erb`
- `app/views/admin/ai_usage/index.html.erb`
- `app/views/admin/database/import_form.html.erb`
- `app/views/blog/show.html.erb`
- `app/views/admin/media/show.html.erb`
- `config/routes.rb`

### 新規追加
- `app/services/security_logger.rb`
- `app/models/concerns/media_validatable.rb`
- `app/javascript/controllers/clipboard_controller.js`
- `config/initializers/security_headers.rb`
- `spec/security/*`
- `spec/services/security_logger_spec.rb`
- `spec/system/security/*`
- `docs/security/SECURITY_GUIDE.md`

---

## 2. テスト結果

### 実行コマンド
```bash
docker compose exec web env RAILS_ENV=test COVERAGE=true bundle exec rspec spec/security spec/services/security_logger_spec.rb
```

### 結果
- **91 examples, 0 failures**
- 実行時間: 4.36s

### カバレッジ
- Line Coverage: **15.85% (973 / 6138)**
- **SimpleCov 85% 未達で exit 2**
- 備考: セキュリティ関連 spec のみ実行しているため、全体カバレッジが低く出る

### 補足
Devise の `unprocessable_entity` が Rack で非推奨の警告が出る（テストは通過）。
今後はセキュリティ特化の実行では `COVERAGE=true` を外し、CI/全体テストでカバレッジ判定を行う運用とする。

### 全体テスト（最終）
```bash
docker compose exec web env RAILS_ENV=test COVERAGE=true bundle exec rspec
```

- **837 examples, 0 failures, 24 pending**
- 実行時間: 13.14s
- Line Coverage: **89.28% (3789 / 4244)**

---

## 3. パフォーマンス測定

- 未測定（DB未接続のためテスト未完了）
- 目標: セキュリティチェック影響 50ms 以内

---

## 4. 推奨事項

1. **テスト再実行**
   - DB起動後に `spec/security` を再実行
2. **本番設定の確認**
   - `ADMIN_PATH`, `REDIS_URL`, `ADMIN_WHITELIST_IPS`, `ENABLE_HSTS`, `HSTS_MAX_AGE` の環境変数設定
3. **CSPの段階的強化**
   - インラインスクリプトの削減を継続し、必要に応じて `script-src` の緩和削減
4. **Rack 3 の非推奨警告対応（TODO）**
   - Devise の失敗レスポンスが `:unprocessable_entity` を返すため警告が出る
   - 将来のRack更新に備え、`Devise::FailureApp` のステータスを `:unprocessable_content` に合わせることを検討

---

## 5. トラブルシューティング

### DB未起動によるテスト失敗
- **症状**: `ActiveRecord::ConnectionNotEstablished`
- **対策**: PostgreSQL を起動（Docker環境でのRSpec実行推奨）

---

## 6. セキュリティガイド

- `docs/security/SECURITY_GUIDE.md` を作成済み

---

## 7. 進捗

- 実装: 完了
- テスト: 未完了（DB未接続のため）
- ドキュメント: 完了
