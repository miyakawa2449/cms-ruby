# Pendingテスト整理（初期確認）

## 確認結果
全てRailsのデフォルト生成（scaffold）由来の `pending "add some examples..."` のみで、
現時点で機能仕様やPhase計画に直接紐づく実装済みテストは含まれていません。

## 対象一覧（内容なし・pendingのみ）
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

## 次のアクション案
1. **削除**: 未実装の雛形を削除してpendingをゼロにする
2. **skip化**: `skip "TODO"` に変更し、理由を明記して残す
3. **最小テスト実装**: 主要モデル（Tag/Category/Section など）からバリデーション・関連のスモークテストを追加

