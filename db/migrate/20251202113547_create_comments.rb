class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      
      # 投稿者情報
      t.string :author_name, null: false, limit: 100
      t.string :author_email, null: false
      t.string :author_url, limit: 500
      t.inet :author_ip
      t.text :author_user_agent
      
      # コメント内容
      t.text :content, null: false
      t.text :content_html
      
      # ステータス
      t.string :status, default: 'pending', null: false
      
      # モデレーション
      t.references :moderated_by, foreign_key: { to_table: :admin_users }
      t.datetime :moderated_at
      t.decimal :spam_score, precision: 3, scale: 2, default: 0.0
      
      t.timestamps
    end
    
    # 手動インデックス（クエリ最適化）
    add_index :comments, :status
    add_index :comments, :author_email
    add_index :comments, [:article_id, :status, :created_at]
    
    # 制約
    add_check_constraint :comments, 
                        "status IN ('pending', 'approved', 'spam', 'trash')",
                        name: 'comments_valid_status'
  end
end
