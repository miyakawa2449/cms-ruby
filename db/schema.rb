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

ActiveRecord::Schema[8.1].define(version: 2025_12_03_055832) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
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
    t.text "excerpt"
    t.string "meta_description", limit: 500
    t.string "meta_keywords", limit: 500
    t.string "og_description", limit: 500
    t.string "og_title", limit: 255
    t.datetime "published_at"
    t.string "slug", limit: 255, null: false
    t.string "status", limit: 50, default: "draft"
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_articles_on_admin_user_id"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status", "published_at"], name: "index_articles_on_status_and_published_at"
    t.index ["status"], name: "index_articles_on_status"
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

  create_table "section_contents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "is_active"
    t.datetime "published_at"
    t.bigint "published_by"
    t.bigint "section_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version"
    t.index ["section_id"], name: "index_section_contents_on_section_id"
  end

  create_table "sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.boolean "is_visible"
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sections_on_name", unique: true
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

  add_foreign_key "article_categories", "articles"
  add_foreign_key "article_categories", "categories"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "articles", "admin_users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "section_contents", "sections"
end
