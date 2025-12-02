class CreateArticleMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :article_media, primary_key: [:article_id, :media_file_id] do |t|
      # 複合主キー（Rails 8.0が自動で外部キーインデックス作成）
      t.references :article, null: false, foreign_key: true
      t.references :media_file, null: false, foreign_key: true
      
      t.integer :position, default: 0
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end
    
    # 複合主キーがあるため追加インデックス不要
  end
end
