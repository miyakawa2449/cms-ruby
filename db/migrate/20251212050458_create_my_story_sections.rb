class CreateMyStorySections < ActiveRecord::Migration[8.1]
  def change
    create_table :my_story_sections do |t|
      t.string :section_type, null: false
      t.string :title, null: false
      t.string :subtitle
      t.text :content
      t.jsonb :additional_data, default: {}
      t.integer :position, null: false, default: 0
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    # インデックスを追加
    add_index :my_story_sections, :section_type, unique: true
    add_index :my_story_sections, :position
    add_index :my_story_sections, :is_active
    add_index :my_story_sections, [:is_active, :position]
    add_index :my_story_sections, :additional_data, using: :gin
  end
end
