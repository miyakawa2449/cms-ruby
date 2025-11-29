class CreateArticleRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :article_revisions do |t|
      # Article reference
      t.references :article, null: false, foreign_key: true
      
      # Revision metadata
      t.integer :revision_number, null: false
      t.string :revision_type, default: 'auto', null: false
      t.text :change_summary
      
      # Author information
      t.references :admin_user, null: false, foreign_key: true
      
      # Snapshot data (full content snapshot)
      t.json :content_snapshot, null: false
      t.json :metadata_snapshot, default: {}
      
      # Change tracking
      t.json :content_diff, default: {}
      t.json :metadata_diff, default: {}
      t.text :changes_summary
      
      # Revision flags
      t.boolean :major_revision, default: false, null: false
      t.boolean :published_revision, default: false, null: false
      t.boolean :current_revision, default: true, null: false
      
      # Statistics
      t.integer :word_count_change, default: 0
      t.decimal :content_similarity, precision: 5, scale: 4
      
      t.timestamps null: false
    end

    # Indexes
    add_index :article_revisions, :article_id
    add_index :article_revisions, :admin_user_id
    add_index :article_revisions, :revision_number
    add_index :article_revisions, :revision_type
    add_index :article_revisions, :major_revision
    add_index :article_revisions, :published_revision
    add_index :article_revisions, :current_revision
    add_index :article_revisions, :created_at
    
    # Composite indexes
    add_index :article_revisions, [:article_id, :revision_number], unique: true, name: 'index_article_revisions_unique'
    add_index :article_revisions, [:article_id, :current_revision], name: 'index_article_revisions_current'
    add_index :article_revisions, [:article_id, :published_revision, :created_at], name: 'index_article_revisions_published'
    add_index :article_revisions, [:admin_user_id, :created_at], name: 'index_article_revisions_author_date'
    
    # JSONB indexes
    add_index :article_revisions, :content_snapshot, using: :gin, name: 'index_article_revisions_content_gin'
    add_index :article_revisions, :content_diff, using: :gin, name: 'index_article_revisions_diff_gin'
    
    # Constraints
    add_check_constraint :article_revisions, "revision_type IN ('auto', 'manual', 'scheduled', 'restored')", name: 'article_revisions_valid_type'
    add_check_constraint :article_revisions, "revision_number >= 1", name: 'article_revisions_number_positive'
    add_check_constraint :article_revisions, "content_similarity >= 0 AND content_similarity <= 1 OR content_similarity IS NULL", name: 'article_revisions_similarity_range'
  end
end