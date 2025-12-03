class CreateSectionContents < ActiveRecord::Migration[8.1]
  def change
    create_table :section_contents do |t|
      t.references :section, null: false, foreign_key: true
      t.jsonb :content, null: false, default: '{}'
      t.integer :version, null: false, default: 1
      t.boolean :is_active, default: false
      t.bigint :published_by
      t.datetime :published_at

      t.timestamps
    end
    
    add_foreign_key :section_contents, :admin_users, column: :published_by, on_delete: :nullify
    add_index :section_contents, :content, using: :gin
    add_index :section_contents, :published_by
    add_index :section_contents, [:section_id, :version], unique: true
  end
end
