class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :parent, foreign_key: { to_table: :categories }, null: true
      t.string :name, limit: 100, null: false
      t.string :slug, limit: 100, null: false
      t.text :description
      t.string :icon, limit: 50
      t.string :color, limit: 7
      t.integer :position, default: 0
      t.integer :article_count, default: 0

      t.timestamps
    end
    
    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true
    add_index :categories, :position
  end
end
