# Task 17 デバッグレポート：CSRF 422エラーの原因と解決

**日付**: 2026年4月20日（月）  
**担当**: Claude Code（調査・実装）、Codex（根本原因特定・修正）  
**対象**: Phase 7.3 Task 17 — 管理画面に復元機能を追加  
**ステータス**: ✅ 解決済み（18 examples, 0 failures）

---

## 📋 概要

Task 17（`Admin::BackupsController#restore` アクションとそのテスト）の実装は完了していたが、`spec/requests/admin/backups_spec.rb` の POST テストが 422 Unprocessable Content で失敗し続けた。Claude Code による調査では原因を特定できず、Codex に引き継ぎ。Codex が根本原因を特定・修正し、全 18 件のテストが通過した。

---

## 🔍 症状

```
Admin::Backups POST /admin/backups/restore redirects to backups index
  Expected response to be a <3XX: redirect>, but was a <422: Unprocessable Content>
```

レスポンスボディを確認すると：

```
ActionController::InvalidAuthenticityToken
  at /admin-secure-panel-miyakawa2449/backups/restore
```

---

## ❌ Claude Code が試みた（誤った）方向性

### 試み 1：`protect_from_forgery` 設定の調査
- `config/environments/test.rb` で `allow_forgery_protection = false` を確認
- `rails runner` で `ActionController::Base.allow_forgery_protection` → `false` を確認
- CSRF は無効のはずなのになぜ？と混乱

### 試み 2：ルーティングの変更（collection → member）
- S3 キーにスラッシュが含まれるためURL に埋め込み不可
- `CGI.escape` でエンコードしても Rails/Rack が二重エンコードして 404 に
- 元の collection route に戻す結論に至るも CSRF は未解決

### 見落とした点
- `RAILS_ENV` 環境変数がコンテナに既にセットされている可能性を見ていなかった
- GET テストは CSRF チェックがそもそも発生しないため問題に気づかなかった

---

## ✅ Codex が特定した根本原因

**`spec/rails_helper.rb` の環境変数設定のバグ**

```ruby
# 修正前（問題あり）
ENV['RAILS_ENV'] ||= 'test'

# 修正後（正しい）
ENV['RAILS_ENV'] = 'test'
```

### なぜこれが問題だったか

1. Docker コンテナの `web` サービスはデフォルト `RAILS_ENV=development` で起動している
2. `||=` は「未設定の場合のみ代入」なので、development がすでにセットされていると何もしない
3. 結果として `docker compose exec web rspec ...` は **development 環境で RSpec が動いていた**
4. development 環境では `allow_forgery_protection = true`（デフォルト）のため、CSRF チェックが有効
5. GET リクエストは CSRF 対象外なので問題が顕在化せず、POST だけ 422 になっていた

### なぜ気づきにくかったか

- `rails runner -e test` で `allow_forgery_protection` を確認したため test 環境での値しか見えなかった
- `db:test:load_schema` のエラーがコンソールに出ていたが、これは別件（IPv6 接続エラー）で CSRF とは無関係
- GET テストが全件通過していたため RSpec 自体の問題とは思わなかった

---

## 📁 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `spec/rails_helper.rb` | `ENV['RAILS_ENV'] ||= 'test'` → `ENV['RAILS_ENV'] = 'test'` |

---

## 📊 最終テスト結果

```
Admin::Backups
  GET /admin/backups
    returns HTTP 200                                              ✅
    displays backup file entries                                  ✅
    sorts backups by last_modified descending (newest first)      ✅
    with backup_type filter
      passes backup_type to S3Service                             ✅
      shows the filter form with backup_type options              ✅
    when S3 returns an error
      still returns HTTP 200 (does not crash)                     ✅
      shows an error message                                      ✅
      renders empty backup list                                   ✅
  Property 18: バックアップ一覧ソート
    always displays backups in newest-first order                 ✅
  Property 19: バックアップフィルタリング
    passes the selected type to S3Service as prefix filter        ✅
  POST /admin/backups/restore
    redirects to backups index                                    ✅
    enqueues Restore::RestoreJob                                  ✅
    passes all three category keys to the job                     ✅
    sets a success flash notice                                   ✅
    when backup_key is blank
      redirects with an alert                                     ✅
      does not enqueue the job                                    ✅
    when S3 raises an error
      redirects with an error message                             ✅
      does not enqueue the job                                    ✅

18 examples, 0 failures
```

---

## 🏗️ Task 17 実装内容（完了）

### コントローラー（`app/controllers/admin/backups_controller.rb`）

- `restore` アクション：`params[:backup_key]` からS3キーを取得
- S3から同日同タイプの database/storage/config 3ファイルを検索
- `Restore::RestoreJob.perform_later(backup_keys.stringify_keys)` でジョブをエンキュー
- エラー時は flash alert でリダイレクト

### ビュー（`app/views/admin/backups/index.html.erb`）

- 復元ボタン → モーダル表示（`openRestoreModal(key, date)`）
- モーダル内フォーム → `POST /admin/backups/restore` に `backup_key` を hidden field で送信
- JavaScript でモーダル開閉制御

### ルーティング（`config/routes.rb`）

```ruby
resources :backups, only: [:index] do
  collection do
    post :restore  # S3キーにスラッシュが含まれるため collection route を採用
  end
end
```

---

## 💡 教訓

1. **Docker exec でのテスト実行時は `RAILS_ENV` を明示的に確認する**
   ```bash
   docker compose exec web env | grep RAILS_ENV
   ```

2. **`||=` より `=` を使う**：テスト環境では環境変数を強制上書きすべき

3. **GETは通過するのにPOSTだけ失敗する場合**：CSRF が疑われるが、その前に Rails 環境（development/test）を確認する

4. **デバッグの分担**：環境設定レベルの問題は Claude Code より Codex の方が得意な場合がある

---

## 🚀 次のステップ

- **Task 19**: 統合テスト（バックアップ→S3→保持ポリシー、バックアップ→復元の往復）
- **Task 20**: チェックポイント（全テスト通過確認・85%以上カバレッジ）
- **Task 21**: ドキュメント作成（`docs/backup_restore_guide.md`、`docs/aws_s3_setup_guide.md`）

---

**作成者**: Claude Code + Codex  
**レビュー**: 未実施（Kiro 検証待ち）
