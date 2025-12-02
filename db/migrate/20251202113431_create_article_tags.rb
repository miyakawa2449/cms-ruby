class CreateArticleTags < ActiveRecord::Migration[8.0]
  def change
    create_table :article_tags, primary_key: [:article_id, :tag_id] do |t|
      # 複合主キー（Rails 8.0が自動で外部キーインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 複合主キーがあるため追加インデックス不要
  end
end
