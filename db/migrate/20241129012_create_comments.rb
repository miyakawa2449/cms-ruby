class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      # Article reference
      t.references :article, null: false, foreign_key: true
      
      # Threading support (self-referential)
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      t.integer :depth, default: 0, null: false
      
      # Commenter information
      t.string :author_name, null: false, limit: 100
      t.string :author_email, null: false, limit: 255
      t.string :author_url, limit: 255
      t.inet :author_ip
      t.string :author_user_agent, limit: 500
      
      # Comment content
      t.text :content, null: false
      t.text :content_html
      
      # Moderation
      t.string :status, default: 'pending', null: false
      t.text :moderation_notes
      t.references :moderated_by, null: true, foreign_key: { to_table: :admin_users }
      t.datetime :moderated_at
      
      # Spam detection
      t.decimal :spam_score, precision: 5, scale: 4, default: 0.0
      t.json :spam_flags, default: []
      t.boolean :auto_approved, default: false, null: false
      
      # Statistics
      t.integer :likes_count, default: 0, null: false
      t.integer :replies_count, default: 0, null: false
      
      # Notification
      t.boolean :notify_replies, default: false, null: false
      t.string :notification_token, limit: 32
      
      t.timestamps null: false
    end

    # Indexes
    add_index :comments, :status
    add_index :comments, :author_email
    add_index :comments, :author_ip
    add_index :comments, :spam_score
    add_index :comments, :auto_approved
    add_index :comments, :created_at
    add_index :comments, :notification_token, unique: true
    
    # Composite indexes
    add_index :comments, [:article_id, :status, :created_at], name: 'index_comments_article_status_date'
    add_index :comments, [:article_id, :parent_id, :created_at], name: 'index_comments_thread'
    add_index :comments, [:status, :spam_score], name: 'index_comments_moderation'
    add_index :comments, [:author_email, :created_at], name: 'index_comments_author_date'
    add_index :comments, [:author_ip, :created_at], name: 'index_comments_ip_date'
    
    # Full-text search
    add_index :comments, :content, opclass: :gin_trgm_ops, using: :gin, name: 'index_comments_content_trgm'
    add_index :comments, :author_name, opclass: :gin_trgm_ops, using: :gin, name: 'index_comments_author_name_trgm'
    
    # Performance indexes
    add_index :comments, [:status, :created_at], where: "parent_id IS NULL", name: 'index_comments_top_level'
    add_index :comments, [:spam_score, :created_at], where: "status = 'pending'", name: 'index_comments_pending_spam'
    
    # Constraints
    add_check_constraint :comments, "status IN ('pending', 'approved', 'spam', 'trash')", name: 'comments_valid_status'
    add_check_constraint :comments, "depth >= 0 AND depth <= 5", name: 'comments_depth_range'
    add_check_constraint :comments, "spam_score >= 0 AND spam_score <= 1", name: 'comments_spam_score_range'
    add_check_constraint :comments, "length(content) >= 5", name: 'comments_content_length'
    add_check_constraint :comments, "length(author_name) >= 2", name: 'comments_author_name_length'
    add_check_constraint :comments, "author_email ~ '^[^@]+@[^@]+\.[^@]+$'", name: 'comments_author_email_format'
    add_check_constraint :comments, "likes_count >= 0", name: 'comments_likes_count_positive'
    add_check_constraint :comments, "replies_count >= 0", name: 'comments_replies_count_positive'
    add_check_constraint :comments, "parent_id != id", name: 'comments_no_self_reference'
    
    # Threading constraints
    add_check_constraint :comments, "(parent_id IS NULL AND depth = 0) OR (parent_id IS NOT NULL AND depth > 0)", name: 'comments_depth_consistency'
  end
end