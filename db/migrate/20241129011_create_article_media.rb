class CreateArticleMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :article_media do |t|
      t.references :article, null: false, foreign_key: true
      t.references :media_file, null: false, foreign_key: true
      
      # Media usage context
      t.string :usage_type, null: false
      t.string :alt_text, limit: 200
      t.text :caption
      t.integer :sort_order, default: 0, null: false
      
      # Position in content
      t.string :position, default: 'content'
      t.text :html_attributes, default: '{}'
      
      # Display settings
      t.json :display_settings, default: {}
      t.boolean :lazy_load, default: true, null: false
      
      t.timestamps null: false
    end

    # Indexes
    add_index :article_media, [:article_id, :media_file_id], unique: true, name: 'index_article_media_unique'
    add_index :article_media, :media_file_id
    add_index :article_media, :usage_type
    add_index :article_media, :position
    add_index :article_media, [:article_id, :sort_order], name: 'index_article_media_sort'
    add_index :article_media, [:article_id, :usage_type], name: 'index_article_media_usage'
    add_index :article_media, [:media_file_id, :created_at], name: 'index_article_media_file_date'
    
    # Full-text search
    add_index :article_media, :alt_text, opclass: :gin_trgm_ops, using: :gin, name: 'index_article_media_alt_text_trgm'
    
    # Constraints
    add_check_constraint :article_media, "usage_type IN ('featured_image', 'content_image', 'gallery', 'attachment', 'thumbnail', 'hero', 'background')", name: 'article_media_valid_usage_type'
    add_check_constraint :article_media, "position IN ('content', 'featured', 'hero', 'sidebar', 'footer')", name: 'article_media_valid_position'
    add_check_constraint :article_media, "sort_order >= 0", name: 'article_media_sort_order_positive'
  end
end