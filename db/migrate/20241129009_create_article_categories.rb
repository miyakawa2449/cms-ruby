class CreateArticleCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :article_categories do |t|
      t.references :article, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      
      # Relationship metadata
      t.boolean :primary, default: false, null: false
      t.integer :sort_order, default: 0, null: false
      
      t.timestamps null: false
    end

    # Indexes
    add_index :article_categories, [:article_id, :category_id], unique: true, name: 'index_article_categories_unique'
    add_index :article_categories, :primary
    add_index :article_categories, [:article_id, :primary], name: 'index_article_categories_primary'
    add_index :article_categories, [:article_id, :sort_order], name: 'index_article_categories_sort'
    add_index :article_categories, [:category_id, :created_at], name: 'index_article_categories_category_date'
    
    # Constraints
    add_check_constraint :article_categories, "sort_order >= 0", name: 'article_categories_sort_order_positive'
  end
end