class CreateArticleCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :article_categories, primary_key: [:article_id, :category_id] do |t|
      # 複合主キー（Rails 8.0が自動で外部キーインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      
      t.boolean :is_primary, default: false
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 手動インデックス（クエリ最適化）
    add_index :article_categories, :category_id, 
              where: 'is_primary = true',
              name: 'index_article_categories_primary'
  end
end
