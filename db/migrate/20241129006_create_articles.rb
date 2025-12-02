class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      # Basic article information
      t.string :title, null: false, limit: 200
      t.string :slug, null: false, limit: 150
      t.text :excerpt, limit: 500
      t.text :content, null: false
      t.text :markdown_content
      
      # Publishing information
      t.string :status, default: 'draft', null: false
      t.datetime :published_at
      t.datetime :scheduled_for
      
      # Author information
      t.references :admin_user, null: false, foreign_key: true
      
      # Content metadata
      t.integer :word_count, default: 0, null: false
      t.integer :reading_time, default: 0, null: false
      t.string :language, default: 'ja', null: false
      
      # SEO fields
      t.string :meta_title, limit: 60
      t.text :meta_description, limit: 160
      t.json :meta_keywords, default: []
      t.string :og_image_url
      t.string :canonical_url
      
      # Social media
      t.string :twitter_card, default: 'summary'
      t.text :social_description
      
      # Statistics
      t.integer :views_count, default: 0, null: false
      t.integer :comments_count, default: 0, null: false
      t.integer :likes_count, default: 0, null: false
      t.integer :shares_count, default: 0, null: false
      
      # Features
      t.boolean :featured, default: false, null: false
      t.boolean :pinned, default: false, null: false
      t.boolean :allow_comments, default: true, null: false
      t.boolean :show_in_sitemap, default: true, null: false
      
      # Content settings
      t.json :table_of_contents, default: []
      t.json :custom_fields, default: {}
      t.text :notes
      
      # Full-text search (PostgreSQL tsvector)
      t.virtual :search_vector, type: :tsvector, as: "to_tsvector('english', coalesce(title, '') || ' ' || coalesce(excerpt, '') || ' ' || coalesce(content, ''))", stored: true
      
      t.timestamps null: false
    end

    # Indexes
    add_index :articles, :slug, unique: true
    add_index :articles, :status
    add_index :articles, :published_at
    add_index :articles, :scheduled_for
    add_index :articles, :featured
    add_index :articles, :pinned
    add_index :articles, :language
    add_index :articles, :views_count
    add_index :articles, :created_at
    add_index :articles, :updated_at
    
    # Composite indexes for common queries
    add_index :articles, [:status, :published_at], name: 'index_articles_published'
    add_index :articles, [:featured, :published_at], name: 'index_articles_featured_published'
    add_index :articles, [:pinned, :published_at], name: 'index_articles_pinned_published'
    add_index :articles, [:admin_user_id, :status, :created_at], name: 'index_articles_author_status'
    add_index :articles, [:status, :featured, :published_at], name: 'index_articles_status_featured_date'
    
    # Full-text search index
    add_index :articles, :search_vector, using: :gin, name: 'index_articles_search_vector'
    add_index :articles, :title, opclass: :gin_trgm_ops, using: :gin, name: 'index_articles_title_trgm'
    
    # Performance indexes
    add_index :articles, [:published_at, :id], where: "status = 'published'", name: 'index_articles_published_id'
    add_index :articles, [:views_count, :published_at], where: "status = 'published'", name: 'index_articles_popular'
    
    # Constraints
    add_check_constraint :articles, "status IN ('draft', 'published', 'scheduled', 'archived')", name: 'articles_valid_status'
    add_check_constraint :articles, "language IN ('ja', 'en')", name: 'articles_valid_language'
    add_check_constraint :articles, "twitter_card IN ('summary', 'summary_large_image')", name: 'articles_valid_twitter_card'
    add_check_constraint :articles, "length(title) >= 5", name: 'articles_title_length'
    add_check_constraint :articles, "slug ~ '^[a-z0-9_-]+$'", name: 'articles_slug_format'
    add_check_constraint :articles, "word_count >= 0", name: 'articles_word_count_positive'
    add_check_constraint :articles, "reading_time >= 0", name: 'articles_reading_time_positive'
    add_check_constraint :articles, "views_count >= 0", name: 'articles_views_count_positive'
    add_check_constraint :articles, "comments_count >= 0", name: 'articles_comments_count_positive'
    
    # Status-specific constraints
    add_check_constraint :articles, "(status = 'published' AND published_at IS NOT NULL) OR (status != 'published')", name: 'articles_published_date_required'
    add_check_constraint :articles, "(status = 'scheduled' AND scheduled_for IS NOT NULL) OR (status != 'scheduled')", name: 'articles_scheduled_date_required'
  end
end