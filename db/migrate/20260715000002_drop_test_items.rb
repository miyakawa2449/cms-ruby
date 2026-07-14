class DropTestItems < ActiveRecord::Migration[8.1]
  # DB疎通デバッグ用の残骸テーブルを削除（監査C-6）
  def change
    drop_table :test_items do |t|
      t.string "name", null: false
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
