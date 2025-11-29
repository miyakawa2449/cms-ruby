class CreateArticleTags < ActiveRecord::Migration[8.0]
  def change
    create_table :article_tags do |t|
      t.references :article, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      
      # Relationship metadata
      t.integer :sort_order, default: 0, null: false
      t.boolean :auto_generated, default: false, null: false
      t.decimal :relevance_score, precision: 5, scale: 4, default: 1.0
      
      t.timestamps null: false
    end

    # Indexes
    add_index :article_tags, [:article_id, :tag_id], unique: true, name: 'index_article_tags_unique'
    add_index :article_tags, :tag_id
    add_index :article_tags, :auto_generated
    add_index :article_tags, :relevance_score
    add_index :article_tags, [:article_id, :sort_order], name: 'index_article_tags_sort'
    add_index :article_tags, [:tag_id, :created_at], name: 'index_article_tags_tag_date'
    add_index :article_tags, [:relevance_score, :created_at], name: 'index_article_tags_relevance'
    
    # Constraints
    add_check_constraint :article_tags, "sort_order >= 0", name: 'article_tags_sort_order_positive'
    add_check_constraint :article_tags, "relevance_score >= 0 AND relevance_score <= 1", name: 'article_tags_relevance_score_range'
  end
end