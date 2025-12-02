class CreateArticleAiAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :article_ai_analyses do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :article, null: false, foreign_key: true, index: { unique: true }
      
      # AI生成コンテンツ
      t.text :summary
      t.text :keywords
      t.text :related_topics
      
      # SEO分析（JSONB統一）
      t.decimal :seo_score, precision: 3, scale: 2
      t.jsonb :seo_suggestions, default: {}
      t.decimal :readability_score, precision: 3, scale: 2
      
      # 感情分析
      t.string :sentiment, limit: 50
      t.string :tone, limit: 50
      
      # API情報（JSONB統一）
      t.jsonb :api_metadata, default: {}
      
      t.datetime :analyzed_at, null: false, default: -> { 'NOW()' }
    end
    
    # 手動インデックス（JSONB）
    add_index :article_ai_analyses, :seo_suggestions, using: :gin
    add_index :article_ai_analyses, :api_metadata, using: :gin
  end
end
