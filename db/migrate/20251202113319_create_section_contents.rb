class CreateSectionContents < ActiveRecord::Migration[8.0]
  def change
    create_table :section_contents do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :section, null: false, foreign_key: true
      
      # JSONBでフレキシブルなコンテンツ管理
      t.jsonb :content, null: false, default: {}
      
      # バージョン管理
      t.integer :version, null: false, default: 1
      t.boolean :is_active, default: false
      t.references :published_by, foreign_key: { to_table: :admin_users }
      t.datetime :published_at
      
      t.timestamps
    end
    
    # 手動インデックス（複合・JSONB）
    add_index :section_contents, [:section_id, :is_active]
    add_index :section_contents, [:section_id, :version]
    add_index :section_contents, :content, using: :gin
  end
end
