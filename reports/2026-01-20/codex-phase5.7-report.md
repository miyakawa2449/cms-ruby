# Phase 5.7 テストカバレッジ向上 - レポート

作成日: 2026-01-22  
担当: Codex

---

## 1. テスト実行結果

**作成・更新した主なテストファイル（追加/拡張）**

**ユニットテスト（AI/サービス/モデル/ヘルパー/ジョブ/メール）**
- `spec/services/ai/title_suggester_spec.rb`
- `spec/services/ai/summary_generator_spec.rb`
- `spec/services/ai/tag_suggester_spec.rb`
- `spec/services/ai/slug_generator_spec.rb`
- `spec/services/ai/seo_meta_generator_spec.rb`
- `spec/services/ai/structure_suggester_spec.rb`
- `spec/services/ai/bedrock_client_spec.rb`
- `spec/services/ai/usage_tracker_spec.rb`
- `spec/services/ai/usage_statistics_service_spec.rb`
- `spec/services/article_content_manager_spec.rb`
- `spec/services/article_meta_manager_spec.rb`
- `spec/services/article_publishing_manager_spec.rb`
- `spec/services/article_association_service_spec.rb`
- `spec/services/article_statistics_service_spec.rb`
- `spec/services/media/upload_service_spec.rb`
- `spec/services/media/edit_service_spec.rb`
- `spec/services/ogp_fetcher_service_spec.rb`
- `spec/services/slack_notifier_spec.rb`
- `spec/services/site_assets_service_spec.rb`
- `spec/services/site_setting_cache_manager_spec.rb`
- `spec/services/site_setting_value_manager_spec.rb`
- `spec/services/site_setting_type_manager_spec.rb`
- `spec/services/cache_monitor_service_spec.rb`
- `spec/services/meta_tags_service_spec.rb`
- `spec/services/section_content_activation_service_spec.rb`
- `spec/services/section_content_params_service_spec.rb`
- `spec/services/my_story_section_*_spec.rb`
- `spec/models/concerns/json_storable_spec.rb`
- `spec/models/concerns/positionable_spec.rb`
- `spec/models/concerns/publishable_spec.rb`
- `spec/models/my_story_section_spec.rb`
- `spec/models/section_content_spec.rb`
- `spec/helpers/application_helper_spec.rb`
- `spec/helpers/image_helper_spec.rb`
- `spec/helpers/markdown_helper_spec.rb`
- `spec/helpers/navigation_helper_spec.rb`
- `spec/helpers/section_helper_spec.rb`
- `spec/helpers/time_helper_spec.rb`
- `spec/jobs/contact_notification_job_spec.rb`
- `spec/jobs/media/generate_variants_job_spec.rb`
- `spec/mailers/application_mailer_spec.rb`
- `spec/mailers/contact_mailer_spec.rb`

**統合テスト（管理画面/公開API/公開ページ）**
- `spec/requests/admin/articles_crud_spec.rb`
- `spec/requests/admin/authentication_spec.rb`
- `spec/requests/admin/ai_usage_spec.rb`
- `spec/requests/admin/categories_spec.rb`
- `spec/requests/admin/tags_spec.rb`
- `spec/requests/admin/sections_spec.rb`
- `spec/requests/admin/section_contents_spec.rb`
- `spec/requests/admin/my_story_sections_spec.rb`
- `spec/requests/admin/media_spec.rb`
- `spec/requests/admin/site_settings_spec.rb`
- `spec/requests/admin/database_spec.rb`
- `spec/requests/admin/contacts_spec.rb`
- `spec/requests/api/v1/articles_spec.rb`
- `spec/requests/api/v1/categories_spec.rb`
- `spec/requests/api/v1/tags_spec.rb`
- `spec/requests/api/v1/sections_spec.rb`
- `spec/requests/my_story_spec.rb`
- `spec/requests/simple_test_spec.rb`

**E2Eテスト**
- `spec/system/article_creation_spec.rb`
- `spec/system/media_upload_spec.rb`

**テスト実行結果**
- 実行コマンド: `docker compose exec web env RAILS_ENV=test COVERAGE=true bundle exec rspec --no-fail-fast`
- 結果: 738 examples / 0 failures / 17 pending

---

## 2. カバレッジ測定結果

- Line Coverage: 89.01% (3703 / 4160)
- minimum_coverage 85% を達成
- minimum_coverage_by_file 70% を達成

---

## 3. テスト実行時間

- 11.52秒（Docker内で再実行）

---

## 4. 問題点の洗い出し

1. SystemテストはSelenium/Chromeが無効環境ではpending（17件）
2. フラグメントキャッシュ未実装のためキャッシュ系テストがpending
3. CIは現状Minitest中心（`.github/workflows/ci.yml`）だったためRSpec/coverageを追加対応（対応済み: 2026-01-22）

---

## 5. 改善提案

1. CIに `bundle exec rspec` と `COVERAGE=true` を追加して継続的に監視（実施済み: 2026-01-22）
2. Systemテスト用にCI側でChrome/Chromedriverセットアップを追加
3. キャッシュ実装完了後に pending テストを有効化

---

## 6. 成功基準チェック

- [x] 150件以上のテスト作成
- [x] テストカバレッジ85%以上
- [x] テスト実行時間30分以内
- [x] テスト成功率95%以上
- [x] CI/CD統合完了（RSpec/coverage実行を追加）
- [x] レポート作成完了

---

## 付記

実行コマンド例:

```bash
# Docker内で全RSpec実行（カバレッジ計測）
docker compose exec web env RAILS_ENV=test COVERAGE=true bundle exec rspec --no-fail-fast
```

---

## 7. 作業継続メモ

当日はここで終了し、翌日再開予定。

---

## 8. 追記（2026-01-22）

**CIにRSpec/coverageを追加**
- 更新ファイル: `.github/workflows/ci.yml`
- 追加内容: `rspec` ジョブを新設し、`COVERAGE=true` で `bundle exec rspec --no-fail-fast` を実行

---

## 9. 追記（2026-01-21）

**今朝の作業（Phase 5.7 継続）**
- CI対応の追加作業として、ローカルで `bundle exec rspec --no-fail-fast` を実行
- 結果: `ActiveRecord::ConnectionNotEstablished` が大量発生（`127.0.0.1:5432` / `::1:5432` への接続が「Operation not permitted」）
- タイムアウトも発生したため、ローカル実行は中断

**次の対応予定**
- Docker を再起動し、Docker 内で RSpec を再実行して確認

**再開結果（Docker内で再実行）**
- 実行コマンド: `docker compose exec web env RAILS_ENV=test COVERAGE=true bundle exec rspec --no-fail-fast`
- 結果: 738 examples / 0 failures / 17 pending
- Line Coverage: 89.01% (3703 / 4160)
- 実行時間: 11.52秒

**E2E再確認（SELENIUM=true）**
- 実行コマンド: `SELENIUM=true bundle exec rspec spec/system`
- 結果: 15 examples / 0 failures
- 実行時間: 4.4秒

**公開APIの位置づけ（Phase 3.3の設計方針）**
- 現状：APIは“外部提供・将来用途のための基盤”
- 将来：フロントをSPA化、外部クライアント（モバイル/別フロント）対応、Webhook連携、SSG/ISRなどに使う可能性
  - ※公開AI APIは不要の方針のため、admin AIのみで運用
