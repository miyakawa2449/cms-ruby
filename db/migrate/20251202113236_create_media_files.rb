class CreateMediaFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :media_files do |t|
      # 外部キー（Rails 8.0が自動でインデックス作成）
      t.references :admin_user, null: false, foreign_key: true
      
      # ファイル情報
      t.string :filename, null: false
      t.string :original_filename, null: false
      t.string :content_type, null: false
      t.bigint :file_size, null: false
      
      # ストレージ情報
      t.string :storage_path, null: false, limit: 500
      t.string :storage_provider, default: 'local'
      t.string :cdn_url, limit: 500
      
      # 画像専用情報
      t.integer :width
      t.integer :height
      t.string :thumbnail_path, limit: 500
      t.string :webp_path, limit: 500
      
      # メタデータ
      t.string :alt_text
      t.text :caption
      
      # 使用統計
      t.integer :usage_count, default: 0
      t.datetime :last_used_at
      
      t.timestamps
    end
    
    # 手動インデックス（クエリ最適化）
    add_index :media_files, :content_type
    add_index :media_files, :created_at
  end
end
