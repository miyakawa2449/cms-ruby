class CreateArticleAiAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :article_ai_analyses do |t|
      # Article reference
      t.references :article, null: false, foreign_key: true
      
      # Analysis metadata
      t.string :analysis_type, null: false
      t.string :ai_model, null: false
      t.string :model_version
      t.integer :tokens_used, default: 0
      t.decimal :cost, precision: 8, scale: 4, default: 0.0
      
      # Analysis results
      t.json :analysis_results, null: false, default: {}
      t.json :suggestions, default: []
      t.json :keywords_extracted, default: []
      t.json :entities_detected, default: []
      
      # Scoring
      t.decimal :readability_score, precision: 5, scale: 2
      t.decimal :seo_score, precision: 5, scale: 2
      t.decimal :engagement_score, precision: 5, scale: 2
      t.decimal :quality_score, precision: 5, scale: 2
      
      # Content analysis
      t.text :summary_generated
      t.text :title_suggestions, array: true, default: []
      t.text :meta_description_suggestions, array: true, default: []
      t.json :content_improvements, default: []
      
      # SEO analysis
      t.json :seo_recommendations, default: {}
      t.json :keyword_density, default: {}
      t.integer :estimated_reading_time
      t.string :content_tone
      t.string :content_sentiment
      
      # Processing status
      t.string :status, default: 'pending', null: false
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :processing_time_ms
      
      # Applied changes tracking
      t.boolean :suggestions_applied, default: false, null: false
      t.json :applied_suggestions, default: []
      t.references :applied_by, null: true, foreign_key: { to_table: :admin_users }
      t.datetime :applied_at
      
      t.timestamps null: false
    end

    # Indexes
    add_index :article_ai_analyses, :article_id
    add_index :article_ai_analyses, :analysis_type
    add_index :article_ai_analyses, :ai_model
    add_index :article_ai_analyses, :status
    add_index :article_ai_analyses, :readability_score
    add_index :article_ai_analyses, :seo_score
    add_index :article_ai_analyses, :quality_score
    add_index :article_ai_analyses, :suggestions_applied
    add_index :article_ai_analyses, :created_at
    add_index :article_ai_analyses, :completed_at
    
    # Composite indexes
    add_index :article_ai_analyses, [:article_id, :analysis_type, :created_at], name: 'index_ai_analyses_article_type_date'
    add_index :article_ai_analyses, [:status, :started_at], name: 'index_ai_analyses_status_started'
    add_index :article_ai_analyses, [:ai_model, :model_version, :created_at], name: 'index_ai_analyses_model_version'
    add_index :article_ai_analyses, [:quality_score, :created_at], where: "status = 'completed'", name: 'index_ai_analyses_quality_completed'
    
    # JSONB indexes
    add_index :article_ai_analyses, :analysis_results, using: :gin, name: 'index_ai_analyses_results_gin'
    add_index :article_ai_analyses, :suggestions, using: :gin, name: 'index_ai_analyses_suggestions_gin'
    add_index :article_ai_analyses, :keywords_extracted, using: :gin, name: 'index_ai_analyses_keywords_gin'
    
    # Array indexes
    add_index :article_ai_analyses, :title_suggestions, using: :gin, name: 'index_ai_analyses_title_suggestions_gin'
    
    # Constraints
    add_check_constraint :article_ai_analyses, "analysis_type IN ('content', 'seo', 'readability', 'sentiment', 'keywords', 'summary', 'full')", name: 'ai_analyses_valid_type'
    add_check_constraint :article_ai_analyses, "status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')", name: 'ai_analyses_valid_status'
    add_check_constraint :article_ai_analyses, "tokens_used >= 0", name: 'ai_analyses_tokens_positive'
    add_check_constraint :article_ai_analyses, "cost >= 0", name: 'ai_analyses_cost_positive'
    add_check_constraint :article_ai_analyses, "readability_score >= 0 AND readability_score <= 100 OR readability_score IS NULL", name: 'ai_analyses_readability_range'
    add_check_constraint :article_ai_analyses, "seo_score >= 0 AND seo_score <= 100 OR seo_score IS NULL", name: 'ai_analyses_seo_score_range'
    add_check_constraint :article_ai_analyses, "engagement_score >= 0 AND engagement_score <= 100 OR engagement_score IS NULL", name: 'ai_analyses_engagement_range'
    add_check_constraint :article_ai_analyses, "quality_score >= 0 AND quality_score <= 100 OR quality_score IS NULL", name: 'ai_analyses_quality_range'
    add_check_constraint :article_ai_analyses, "processing_time_ms >= 0 OR processing_time_ms IS NULL", name: 'ai_analyses_processing_time_positive'
  end
end