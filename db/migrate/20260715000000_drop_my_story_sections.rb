class DropMyStorySections < ActiveRecord::Migration[8.1]
  # My Story独立ページの廃止に伴いテーブルを削除（本番データはS3日次バックアップで保全）
  def change
    drop_table :my_story_sections do |t|
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
  end
end
