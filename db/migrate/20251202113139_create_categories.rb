class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      # 自己参照外部キー（Rails 8.0が自動でインデックス作成）
      t.references :parent, null: true, foreign_key: { to_table: :categories }
      
      t.string :name, null: false, limit: 100
      t.string :slug, null: false, limit: 100
      t.text :description
      t.string :icon, limit: 50
      t.string :color, limit: 7
      t.integer :position, default: 0
      t.integer :article_count, default: 0
      
      t.timestamps
    end
    
    # 複合インデックス（階層スラッグの一意性確保）
    add_index :categories, [:slug, :parent_id], unique: true
    add_index :categories, :position
  end
end
