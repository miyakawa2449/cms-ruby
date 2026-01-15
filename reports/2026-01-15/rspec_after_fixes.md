# RSpec実行結果（修正後）

## 実行概要
- **実行コマンド**: `docker-compose exec -e DB_HOST=db -e RAILS_ENV=test web bundle exec rspec`
- **実行者**: User（ターミナル実行）
- **実行日**: 2026-01-15

## 結果サマリ
- **総テスト数**: 272
- **失敗**: 0
- **pending**: 18
- **完了時間**: 3.44秒
- **Randomized seed**: 33703

## pending一覧
- `spec/models/tag_spec.rb`
- `spec/models/slack_notification_spec.rb`
- `spec/models/site_setting_spec.rb`
- `spec/models/contact_spec.rb`
- `spec/helpers/contacts_helper_spec.rb`
- `spec/models/admin_user_spec.rb`
- `spec/helpers/admin/contacts_helper_spec.rb`
- `spec/views/admin/site_settings/update.html.tailwindcss_spec.rb`
- `spec/models/section_spec.rb`
- `spec/models/category_spec.rb`
- `spec/views/admin/site_settings/edit.html.tailwindcss_spec.rb`
- `spec/jobs/contact_notification_job_spec.rb`
- `spec/models/article_category_spec.rb`
- `spec/views/admin/site_settings/show.html.tailwindcss_spec.rb`
- `spec/views/admin/site_settings/index.html.tailwindcss_spec.rb`
- `spec/models/article_tag_spec.rb`
- `spec/models/section_content_spec.rb`
- `spec/helpers/admin/site_settings_helper_spec.rb`

## 補足
- 失敗は0件。pendingは既存の未実装テストが対象。
- 本実行はDocker環境（DB_HOST=db, RAILS_ENV=test）で実施。

---

## RSpec再実行結果（pending削除後）
- **実行コマンド**: `docker-compose exec -e DB_HOST=db -e RAILS_ENV=test web bundle exec rspec`
- **実行者**: User（ターミナル実行）
- **実行日**: 2026-01-15
- **総テスト数**: 254
- **失敗**: 0
- **pending**: 0
- **完了時間**: 3.46秒
- **Randomized seed**: 57227
