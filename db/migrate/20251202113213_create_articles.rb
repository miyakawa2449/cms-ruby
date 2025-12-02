class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :admin_user, null: false, foreign_key: true
      
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content, null: false
      t.text :content_html
      t.text :excerpt
      
      # ステータス管理
      t.string :status, default: 'draft', null: false
      t.datetime :published_at
      
      # SEO設定
      t.string :meta_description, limit: 500
      t.string :meta_keywords, limit: 500
      t.string :og_title
      t.string :og_description, limit: 500
      t.string :og_image_url, limit: 500
      
      # 統計
      t.integer :view_count, default: 0
      t.integer :comment_count, default: 0
      t.integer :reading_time
      
      # AI分析結果
      t.text :ai_summary
      t.text :ai_keywords
      t.decimal :ai_seo_score, precision: 3, scale: 2
      
      # バージョン管理
      t.integer :revision_count, default: 0
      
      # 全文検索用（PostgreSQL Alpine = 英語辞書）
      t.tsvector :search_vector
      
      t.timestamps
    end
    
    # 手動インデックス（パフォーマンス最適化）
    add_index :articles, :slug, unique: true
    add_index :articles, :search_vector, using: :gin
    add_index :articles, [:status, :published_at], 
              where: "status = 'published'"
    
    # 制約
    add_check_constraint :articles, 
                        "status IN ('draft', 'published', 'scheduled', 'archived')",
                        name: 'articles_valid_status'
  end
end
