# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_02_114400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "access_logs", primary_key: ["id", "created_at"], options: "PARTITION BY RANGE (created_at)", force: :cascade do |t|
    t.bigserial "id", null: false
    t.string "path", limit: 500, null: false
    t.string "method", limit: 10, null: false
    t.integer "status_code"
    t.inet "ip_address"
    t.text "user_agent"
    t.string "referrer", limit: 500
    t.integer "response_time"
    t.bigint "admin_user_id"
    t.string "session_id", limit: 255
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
  end

  create_table "access_logs_2025_12", primary_key: ["id", "created_at"], options: "INHERITS (access_logs)", force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('access_logs_id_seq'::regclass)" }, null: false
    t.string "path", limit: 500, null: false
    t.string "method", limit: 10, null: false
    t.integer "status_code"
    t.inet "ip_address"
    t.text "user_agent"
    t.string "referrer", limit: 500
    t.integer "response_time"
    t.bigint "admin_user_id"
    t.string "session_id", limit: 255
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.index ["admin_user_id"], name: "index_access_logs_2025_12_on_admin_user_id"
    t.index ["created_at"], name: "index_access_logs_2025_12_on_created_at"
    t.index ["path"], name: "index_access_logs_2025_12_on_path"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "avatar_url"
    t.string "role", default: "author"
    t.jsonb "settings", default: {}
    t.string "api_token"
    t.boolean "otp_required_for_login", default: false
    t.index ["api_token"], name: "index_admin_users_on_api_token", unique: true
    t.index ["confirmation_token"], name: "index_admin_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_admin_users_on_role"
    t.index ["unlock_token"], name: "index_admin_users_on_unlock_token", unique: true
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'editor'::character varying, 'author'::character varying, 'viewer'::character varying]::text[])", name: "admin_users_valid_role"
  end

  create_table "article_ai_analyses", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.text "summary"
    t.text "keywords"
    t.text "related_topics"
    t.decimal "seo_score", precision: 3, scale: 2
    t.jsonb "seo_suggestions", default: {}
    t.decimal "readability_score", precision: 3, scale: 2
    t.string "sentiment", limit: 50
    t.string "tone", limit: 50
    t.jsonb "api_metadata", default: {}
    t.datetime "analyzed_at", default: -> { "now()" }, null: false
    t.index ["api_metadata"], name: "index_article_ai_analyses_on_api_metadata", using: :gin
    t.index ["article_id"], name: "index_article_ai_analyses_on_article_id", unique: true
    t.index ["seo_suggestions"], name: "index_article_ai_analyses_on_seo_suggestions", using: :gin
  end

  create_table "article_categories", primary_key: ["article_id", "category_id"], force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "category_id", null: false
    t.boolean "is_primary", default: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.index ["article_id"], name: "index_article_categories_on_article_id"
    t.index ["category_id"], name: "index_article_categories_on_category_id"
    t.index ["category_id"], name: "index_article_categories_primary", where: "(is_primary = true)"
  end

  create_table "article_media", primary_key: ["article_id", "media_file_id"], force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "media_file_id", null: false
    t.integer "position", default: 0
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.index ["article_id"], name: "index_article_media_on_article_id"
    t.index ["media_file_id"], name: "index_article_media_on_media_file_id"
  end

  create_table "article_revisions", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "admin_user_id", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.integer "revision_number", null: false
    t.string "change_summary", limit: 500
    t.jsonb "metadata", default: {}
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.index ["admin_user_id"], name: "index_article_revisions_on_admin_user_id"
    t.index ["article_id", "revision_number"], name: "index_article_revisions_on_article_id_and_revision_number", unique: true
    t.index ["article_id"], name: "index_article_revisions_on_article_id"
    t.index ["created_at"], name: "index_article_revisions_on_created_at"
    t.index ["metadata"], name: "index_article_revisions_on_metadata", using: :gin
  end

  create_table "article_tags", primary_key: ["article_id", "tag_id"], force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.text "content", null: false
    t.text "content_html"
    t.text "excerpt"
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.string "meta_description", limit: 500
    t.string "meta_keywords", limit: 500
    t.string "og_title"
    t.string "og_description", limit: 500
    t.string "og_image_url", limit: 500
    t.integer "view_count", default: 0
    t.integer "comment_count", default: 0
    t.integer "reading_time"
    t.text "ai_summary"
    t.text "ai_keywords"
    t.decimal "ai_seo_score", precision: 3, scale: 2
    t.integer "revision_count", default: 0
    t.tsvector "search_vector"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_articles_on_admin_user_id"
    t.index ["search_vector"], name: "index_articles_on_search_vector", using: :gin
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status", "published_at"], name: "index_articles_on_status_and_published_at", where: "((status)::text = 'published'::text)"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying, 'scheduled'::character varying, 'archived'::character varying]::text[])", name: "articles_valid_status"
  end

  create_table "backups", force: :cascade do |t|
    t.string "backup_type", limit: 50, null: false
    t.string "status", limit: 50, null: false
    t.string "filename"
    t.bigint "file_size"
    t.string "storage_location", limit: 500
    t.integer "duration_seconds"
    t.integer "tables_count"
    t.integer "records_count"
    t.text "error_message"
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.index ["backup_type"], name: "index_backups_on_backup_type"
    t.index ["started_at"], name: "index_backups_on_started_at"
    t.index ["status"], name: "index_backups_on_status"
    t.check_constraint "backup_type::text = ANY (ARRAY['full'::character varying, 'incremental'::character varying, 'database'::character varying, 'media'::character varying]::text[])", name: "backups_valid_type"
    t.check_constraint "status::text = ANY (ARRAY['running'::character varying, 'completed'::character varying, 'failed'::character varying]::text[])", name: "backups_valid_status"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "parent_id"
    t.string "name", limit: 100, null: false
    t.string "slug", limit: 100, null: false
    t.text "description"
    t.string "icon", limit: 50
    t.string "color", limit: 7
    t.integer "position", default: 0
    t.integer "article_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug", "parent_id"], name: "index_categories_on_slug_and_parent_id", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "parent_id"
    t.string "author_name", limit: 100, null: false
    t.string "author_email", null: false
    t.string "author_url", limit: 500
    t.inet "author_ip"
    t.text "author_user_agent"
    t.text "content", null: false
    t.text "content_html"
    t.string "status", default: "pending", null: false
    t.bigint "moderated_by_id"
    t.datetime "moderated_at"
    t.decimal "spam_score", precision: 3, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "status", "created_at"], name: "index_comments_on_article_id_and_status_and_created_at"
    t.index ["article_id"], name: "index_comments_on_article_id"
    t.index ["author_email"], name: "index_comments_on_author_email"
    t.index ["moderated_by_id"], name: "index_comments_on_moderated_by_id"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["status"], name: "index_comments_on_status"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'spam'::character varying, 'trash'::character varying]::text[])", name: "comments_valid_status"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "email", null: false
    t.string "subject", null: false
    t.text "message", null: false
    t.inet "ip_address"
    t.text "user_agent"
    t.string "referrer", limit: 500
    t.string "status", default: "unread", null: false
    t.bigint "assigned_to_id"
    t.datetime "replied_at"
    t.text "notes"
    t.decimal "spam_score", precision: 3, scale: 2
    t.boolean "is_spam", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_contacts_on_assigned_to_id"
    t.index ["created_at"], name: "index_contacts_on_created_at"
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["status"], name: "index_contacts_on_status"
    t.check_constraint "status::text = ANY (ARRAY['unread'::character varying, 'read'::character varying, 'replied'::character varying, 'archived'::character varying]::text[])", name: "contacts_valid_status"
  end

  create_table "media_files", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.string "filename", null: false
    t.string "original_filename", null: false
    t.string "content_type", null: false
    t.bigint "file_size", null: false
    t.string "storage_path", limit: 500, null: false
    t.string "storage_provider", default: "local"
    t.string "cdn_url", limit: 500
    t.integer "width"
    t.integer "height"
    t.string "thumbnail_path", limit: 500
    t.string "webp_path", limit: 500
    t.string "alt_text"
    t.text "caption"
    t.integer "usage_count", default: 0
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_media_files_on_admin_user_id"
    t.index ["content_type"], name: "index_media_files_on_content_type"
    t.index ["created_at"], name: "index_media_files_on_created_at"
  end

  create_table "section_contents", force: :cascade do |t|
    t.bigint "section_id", null: false
    t.jsonb "content", default: {}, null: false
    t.integer "version", default: 1, null: false
    t.boolean "is_active", default: false
    t.bigint "published_by_id"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content"], name: "index_section_contents_on_content", using: :gin
    t.index ["published_by_id"], name: "index_section_contents_on_published_by_id"
    t.index ["section_id", "is_active"], name: "index_section_contents_on_section_id_and_is_active"
    t.index ["section_id", "version"], name: "index_section_contents_on_section_id_and_version"
    t.index ["section_id"], name: "index_section_contents_on_section_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "name", null: false
    t.string "display_name", null: false
    t.boolean "is_visible", default: true
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sections_on_name", unique: true
    t.index ["position"], name: "index_sections_on_position"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "value_type", default: "string"
    t.string "category", null: false
    t.text "description"
    t.boolean "is_sensitive", default: false
    t.jsonb "json_value", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_settings_on_category"
    t.index ["json_value"], name: "index_settings_on_json_value", using: :gin
    t.index ["key"], name: "index_settings_on_key", unique: true
    t.check_constraint "value_type::text = ANY (ARRAY['string'::character varying, 'integer'::character varying, 'boolean'::character varying, 'jsonb'::character varying]::text[])", name: "settings_valid_value_type"
  end

  create_table "slack_notifications", force: :cascade do |t|
    t.string "notification_type", limit: 50, null: false
    t.bigint "reference_id"
    t.string "reference_type", limit: 50
    t.string "webhook_url", limit: 500
    t.string "channel", limit: 100
    t.jsonb "payload", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.integer "retry_count", default: 0
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "sent_at"
    t.index ["created_at"], name: "index_slack_notifications_on_created_at"
    t.index ["notification_type"], name: "index_slack_notifications_on_notification_type"
    t.index ["payload"], name: "index_slack_notifications_on_payload", using: :gin
    t.index ["status"], name: "index_slack_notifications_on_status"
    t.check_constraint "notification_type::text = ANY (ARRAY['contact'::character varying, 'article_published'::character varying, 'comment'::character varying, 'error'::character varying]::text[])", name: "slack_notifications_valid_type"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "article_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  add_foreign_key "access_logs_2025_12", "admin_users", name: "fk_access_logs_2025_12_admin_user"
  add_foreign_key "article_ai_analyses", "articles"
  add_foreign_key "article_categories", "articles"
  add_foreign_key "article_categories", "categories"
  add_foreign_key "article_media", "articles"
  add_foreign_key "article_media", "media_files"
  add_foreign_key "article_revisions", "admin_users"
  add_foreign_key "article_revisions", "articles"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "articles", "admin_users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "comments", "admin_users", column: "moderated_by_id"
  add_foreign_key "comments", "articles"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "contacts", "admin_users", column: "assigned_to_id"
  add_foreign_key "media_files", "admin_users"
  add_foreign_key "section_contents", "admin_users", column: "published_by_id"
  add_foreign_key "section_contents", "sections"
end
