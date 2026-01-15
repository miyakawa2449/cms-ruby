# テスト失敗分析レポート

## 基本情報
- **日時**: 2026-01-15
- **実行環境**: Docker内 (`docker-compose exec -e DB_HOST=db web bundle exec rspec`)
- **RSpecバージョン**: 3.13.6
- **Rails バージョン**: 8.1.1

## テスト結果サマリー

| 項目 | 数 |
|------|-----|
| 総テスト数 | 274 |
| 成功 | 193 (70.4%) |
| 失敗 | 63 (23.0%) |
| 保留(pending) | 18 (6.6%) |
| 実行時間 | 56.66秒 |

---

## 失敗の分類と原因分析

### カテゴリ1: 認証スコープ指定漏れ（32件）

**症状**: HTTP 403 Forbidden

**原因**: Devise の `sign_in` ヘルパーで `scope: :admin_user` が指定されていない

**該当ファイル**:
| ファイル | 失敗数 |
|---------|--------|
| `spec/requests/admin/article_images_spec.rb` | 8 |
| `spec/requests/admin/contacts_spec.rb` | 4 |
| `spec/requests/admin/site_settings_spec.rb` | 2 |
| `spec/requests/admin/ai_spec.rb` | 16 |
| `spec/requests/admin/ai_controller_spec.rb` | 2 |

**修正方法**:
```ruby
# 修正前
before do
  sign_in admin_user
end

# 修正後
before do
  sign_in admin_user, scope: :admin_user
end
```

**修正の難易度**: 低（機械的な置換で対応可能）

---

### カテゴリ2: テストデータ分離問題（13件）

**症状**: 期待値と実際の件数が一致しない

**原因**:
- `create_list(:article, 3)` で3件作成後、`Article.count` が9件になる
- 他のテストで作成されたデータがクリーンアップされていない
- `database_cleaner` の設定不足、または `transactional fixtures` の問題

**該当ファイル**:
| ファイル | 失敗数 | 詳細 |
|---------|--------|------|
| `spec/models/article_spec.rb` | 9 | by_category, search, by_tag, by_tags |
| `spec/controllers/blog_controller_spec.rb` | 4 | 検索・フィルタ関連 |

**修正方法**:

**Option A**: テストの書き方を修正
```ruby
# 修正前（固定値を期待）
it 'タグIDが空文字の場合、全件を返す' do
  create_list(:article, 3)
  result = Article.by_tag('')
  expect(result.count).to eq(3)  # ❌ 他のテストのデータも含まれる
end

# 修正後（相対的な期待値）
it 'タグIDが空文字の場合、全件を返す' do
  create_list(:article, 3)
  result = Article.by_tag('')
  expect(result.count).to eq(Article.count)  # ✅
end
```

**Option B**: Database Cleaner の設定確認
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.use_transactional_fixtures = true

  # または database_cleaner を使用
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
end
```

**修正の難易度**: 中（テスト設計の見直しが必要）

---

### カテゴリ3: コントローラーテストの設定問題（9件）

**症状**: BlogController のテストが全て失敗

**原因**:
- `type: :controller` スペックで認証やルーティングの問題
- `request` スペックと `controller` スペックの混同

**該当ファイル**:
- `spec/controllers/blog_controller_spec.rb` (9件)

**修正方法**:
- `type: :controller` から `type: :request` への移行を検討
- または適切なテストヘルパーの設定

**修正の難易度**: 中

---

### カテゴリ4: 公開コンタクトフォームのテスト（3件）

**症状**: HTTP 403 Forbidden

**原因**:
- CSRF トークンの検証
- JSON リクエストの形式

**該当ファイル**:
- `spec/requests/contacts_spec.rb` (3件)

**修正方法**:
```ruby
# JSON APIとしてテスト
post contacts_path, params: valid_params, as: :json
```

**修正の難易度**: 低

---

### カテゴリ5: AIサービステスト（3件）

**症状**: モックが正しく動作しない

**原因**:
- `Ai::TitleSuggester` の初期化パラメータの問題
- モックの設定タイミング

**該当ファイル**:
- `spec/services/ai/title_suggester_spec.rb` (3件)

**修正方法**: サービスクラスの実装に合わせてテストを修正

**修正の難易度**: 中

---

### カテゴリ6: エッジケーステスト（3件）

**症状**: 特殊文字を含む検索が期待通り動作しない

**原因**:
- PostgreSQL の全文検索でのエスケープ処理
- バックスラッシュ、SQLワイルドカード（%, _）の扱い

**該当ファイル**:
- `spec/models/article_spec.rb` (3件)

**修正方法**:
- pg_search の設定確認
- または仕様としてテストを修正（これらのエッジケースは対応しない判断も可能）

**修正の難易度**: 高（仕様の検討が必要）

---

## 保留中テスト（18件）

スキャフォールドで自動生成され、未実装のままのテスト:

| ファイル | 内容 |
|---------|------|
| `spec/models/contact_spec.rb` | Contactモデルのテスト |
| `spec/models/site_setting_spec.rb` | SiteSettingモデルのテスト |
| `spec/models/admin_user_spec.rb` | AdminUserモデルのテスト |
| `spec/models/tag_spec.rb` | Tagモデルのテスト |
| `spec/models/category_spec.rb` | Categoryモデルのテスト |
| `spec/models/section_spec.rb` | Sectionモデルのテスト |
| `spec/models/section_content_spec.rb` | SectionContentモデルのテスト |
| `spec/models/article_category_spec.rb` | ArticleCategoryモデルのテスト |
| `spec/models/article_tag_spec.rb` | ArticleTagモデルのテスト |
| `spec/models/slack_notification_spec.rb` | SlackNotificationモデルのテスト |
| `spec/helpers/*_spec.rb` | 各種ヘルパーのテスト |
| `spec/views/*_spec.rb` | ビューのテスト |
| `spec/jobs/*_spec.rb` | ジョブのテスト |

**対応方針**:
- 必要なテストは実装する
- 不要なスキャフォールドテストは削除する

---

## `.rspec` 設定について

### 現在の設定
```
--require spec_helper
--format documentation
--color
--fail-fast
--order random
```

### `--fail-fast` の影響

| 設定 | メリット | デメリット |
|------|---------|-----------|
| あり | 開発中に素早くフィードバック | 全体像が把握しにくい |
| なし | 全テストの状況を把握可能 | 実行時間が長くなる |

### 推奨設定

**開発時**: `--fail-fast` あり（素早いフィードバック）

**CI/CD時**: `--fail-fast` なし + `--format progress`
```bash
bundle exec rspec --no-fail-fast --format progress
```

---

## 修正優先度と工数見積もり

| 優先度 | カテゴリ | 件数 | 工数 | 理由 |
|--------|---------|------|------|------|
| 高 | 認証スコープ | 32 | 30分 | 機械的置換で対応可能 |
| 高 | 公開コンタクト | 3 | 15分 | 簡単な修正 |
| 中 | テストデータ分離 | 13 | 2時間 | 設計見直しが必要 |
| 中 | AIサービステスト | 3 | 1時間 | モック設定の調整 |
| 低 | BlogController | 9 | 2時間 | type変更の検討 |
| 低 | エッジケース | 3 | 要検討 | 仕様判断が必要 |

**総見積もり工数**: 約6時間

---

## 推奨アクションプラン

### Phase 1: 即時対応（30分）
1. 認証スコープの一括修正
2. 公開コンタクトフォームテストの修正

### Phase 2: 短期対応（2-3時間）
1. テストデータ分離問題の解決
2. AIサービステストの修正

### Phase 3: 中期対応（2-3時間）
1. BlogControllerテストの見直し
2. 不要なスキャフォールドテストの削除

### Phase 4: 検討事項
1. エッジケーステストの仕様確認
2. CI/CD導入時のテスト設定

---

## 実行コマンド集

```bash
# 全テスト実行（fail-fast なし）
docker-compose exec -e DB_HOST=db web bundle exec rspec --no-fail-fast

# 特定ファイルのみ実行
docker-compose exec -e DB_HOST=db web bundle exec rspec spec/requests/admin/contacts_spec.rb

# 失敗したテストのみ再実行
docker-compose exec -e DB_HOST=db web bundle exec rspec --only-failures

# カバレッジレポート生成（SimpleCov導入後）
docker-compose exec -e DB_HOST=db web bundle exec rspec --format html --out coverage/rspec.html
```

---

## 関連ドキュメント

- Phase計画書: `docs/development/phase_plan_rails_8_1_1.md`
  - Phase 5.7: テストカバレッジ向上
- コーディング規約: `docs/handoff/conventions.md`
- TDDワークフロー: `docs/handoff/tdd_workflow.md`

---

**作成者**: Claude Code
**作成日**: 2026-01-15
