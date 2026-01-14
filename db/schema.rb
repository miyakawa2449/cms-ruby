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

ActiveRecord::Schema[8.1].define(version: 2026_01_14_081607) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admin_users_on_unlock_token", unique: true
  end

  create_table "ai_generations", force: :cascade do |t|
    t.bigint "admin_user_id"
    t.bigint "article_id"
    t.decimal "cost", precision: 10, scale: 6, default: "0.0"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "generation_type", null: false
    t.text "input_content"
    t.string "model_used"
    t.jsonb "output_data", default: {}
    t.string "status", default: "pending"
    t.integer "tokens_used", default: 0
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_ai_generations_on_admin_user_id"
    t.index ["article_id"], name: "index_ai_generations_on_article_id"
    t.index ["created_at"], name: "index_ai_generations_on_created_at"
    t.index ["generation_type"], name: "index_ai_generations_on_generation_type"
    t.index ["status"], name: "index_ai_generations_on_status"
  end

  create_table "ai_usage_stats", force: :cascade do |t|
    t.string "ai_model", null: false
    t.jsonb "breakdown", default: {}
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "total_cost", precision: 10, scale: 2, default: "0.0"
    t.integer "total_requests", default: 0
    t.integer "total_tokens", default: 0
    t.datetime "updated_at", null: false
    t.index ["date", "ai_model"], name: "index_ai_usage_stats_on_date_and_ai_model", unique: true
    t.index ["date"], name: "index_ai_usage_stats_on_date"
  end

  create_table "article_categories", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "category_id"], name: "index_article_categories_on_article_id_and_category_id", unique: true
    t.index ["article_id"], name: "index_article_categories_on_article_id"
    t.index ["category_id"], name: "index_article_categories_on_category_id"
  end

  create_table "article_tags", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "tag_id"], name: "index_article_tags_on_article_id_and_tag_id", unique: true
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.text "content", null: false
    t.text "content_html"
    t.datetime "created_at", null: false
    t.string "demo_url"
    t.text "excerpt"
    t.string "github_url"
    t.string "meta_description", limit: 500
    t.string "meta_keywords", limit: 500
    t.string "og_description", limit: 500
    t.string "og_title", limit: 255
    t.datetime "published_at"
    t.string "slug", limit: 255, null: false
    t.string "status", limit: 50, default: "draft"
    t.text "tech_stack"
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.string "work_type"
    t.index ["admin_user_id"], name: "index_articles_on_admin_user_id"
    t.index ["content"], name: "index_articles_on_content_gin_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["excerpt"], name: "index_articles_on_excerpt_gin_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status", "published_at"], name: "index_articles_on_status_and_published_at"
    t.index ["status"], name: "index_articles_on_status"
    t.index ["title"], name: "index_articles_on_title_gin_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "categories", force: :cascade do |t|
    t.integer "article_count", default: 0
    t.string "color", limit: 7
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon", limit: 50
    t.string "name", limit: 100, null: false
    t.bigint "parent_id"
    t.integer "position", default: 0
    t.string "slug", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.inet "ip_address"
    t.boolean "is_spam", default: false
    t.text "message"
    t.string "name"
    t.text "notes"
    t.string "referrer"
    t.datetime "replied_at", precision: nil
    t.decimal "spam_score", precision: 3, scale: 2
    t.string "status", default: "unread"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index ["assigned_to_id"], name: "index_contacts_on_assigned_to_id"
    t.index ["created_at"], name: "index_contacts_on_created_at"
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["status"], name: "index_contacts_on_status"
  end

  create_table "media_metadata", force: :cascade do |t|
    t.string "alt_text"
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.bigint "file_size"
    t.integer "height"
    t.string "mime_type"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0
    t.jsonb "variants", default: {}
    t.integer "width"
    t.index ["blob_id"], name: "index_media_metadata_on_blob_id", unique: true
    t.index ["created_at"], name: "index_media_metadata_on_created_at"
    t.index ["mime_type"], name: "index_media_metadata_on_mime_type"
    t.index ["usage_count"], name: "index_media_metadata_on_usage_count"
  end

  create_table "my_story_sections", force: :cascade do |t|
    t.text "achievements"
    t.jsonb "additional_data", default: {}
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.text "quote"
    t.string "section_type", null: false
    t.text "skills"
    t.string "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["additional_data"], name: "index_my_story_sections_on_additional_data", using: :gin
    t.index ["is_active", "position"], name: "index_my_story_sections_on_is_active_and_position"
    t.index ["is_active"], name: "index_my_story_sections_on_is_active"
    t.index ["position"], name: "index_my_story_sections_on_position"
    t.index ["section_type"], name: "index_my_story_sections_on_section_type", unique: true
  end

  create_table "section_contents", force: :cascade do |t|
    t.text "backend_skills"
    t.string "badge_text"
    t.text "career_description"
    t.jsonb "content", default: {}, null: false
    t.text "core_skills"
    t.datetime "created_at", null: false
    t.string "cta_button_text"
    t.text "cta_description"
    t.string "cta_primary_text"
    t.string "cta_primary_url"
    t.string "cta_secondary_text"
    t.string "cta_secondary_url"
    t.text "experience_text"
    t.text "frontend_skills"
    t.boolean "is_active", default: false
    t.text "main_message"
    t.text "main_title"
    t.text "phase1_description"
    t.string "phase1_period"
    t.string "phase1_title"
    t.string "phase1_year"
    t.text "phase2_description"
    t.string "phase2_period"
    t.string "phase2_title"
    t.string "phase2_year"
    t.text "phase3_description"
    t.string "phase3_period"
    t.string "phase3_title"
    t.string "phase3_year"
    t.text "profile_text"
    t.datetime "published_at"
    t.bigint "published_by"
    t.bigint "section_id", null: false
    t.text "sub_message"
    t.text "sub_title"
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["content"], name: "index_section_contents_on_content", using: :gin
    t.index ["published_by"], name: "index_section_contents_on_published_by"
    t.index ["section_id", "version"], name: "index_section_contents_on_section_id_and_version", unique: true
    t.index ["section_id"], name: "index_section_contents_on_section_id"
  end

  create_table "sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", limit: 100, null: false
    t.boolean "is_visible", default: true
    t.string "name", limit: 100, null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sections_on_name", unique: true
    t.index ["position"], name: "index_sections_on_position"
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "setting_type", default: "text"
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "slack_notifications", force: :cascade do |t|
    t.string "channel"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "notification_type"
    t.text "payload"
    t.bigint "reference_id"
    t.string "reference_type"
    t.integer "retry_count", default: 0
    t.datetime "sent_at", precision: nil
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.string "webhook_url"
    t.index ["created_at"], name: "index_slack_notifications_on_created_at"
    t.index ["notification_type"], name: "index_slack_notifications_on_notification_type"
    t.index ["status"], name: "index_slack_notifications_on_status"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.integer "article_count", default: 0
    t.datetime "created_at", null: false
    t.string "name", limit: 50, null: false
    t.string "slug", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "test_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_generations", "admin_users"
  add_foreign_key "ai_generations", "articles"
  add_foreign_key "article_categories", "articles"
  add_foreign_key "article_categories", "categories"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "articles", "admin_users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "contacts", "admin_users", column: "assigned_to_id"
  add_foreign_key "media_metadata", "active_storage_blobs", column: "blob_id"
  add_foreign_key "section_contents", "admin_users", column: "published_by", on_delete: :nullify
  add_foreign_key "section_contents", "sections"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
