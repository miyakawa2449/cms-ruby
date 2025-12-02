class CreateArticleRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :article_revisions do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :admin_user, null: false, foreign_key: true
      
      # リビジョンデータ
      t.string :title, null: false
      t.text :content, null: false
      
      # 変更情報
      t.integer :revision_number, null: false
      t.string :change_summary, limit: 500
      
      # メタデータ（JSONB統一）
      t.jsonb :metadata, default: {}
      
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 手動インデックス（複合・JSONB）
    add_index :article_revisions, [:article_id, :revision_number], unique: true
    add_index :article_revisions, :created_at
    add_index :article_revisions, :metadata, using: :gin
  end
end
