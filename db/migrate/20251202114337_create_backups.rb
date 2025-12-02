class CreateBackups < ActiveRecord::Migration[8.0]
  def change
    create_table :backups do |t|
      # バックアップ情報
      t.string :backup_type, null: false, limit: 50
      t.string :status, null: false, limit: 50
      
      # ファイル情報
      t.string :filename
      t.bigint :file_size
      t.string :storage_location, limit: 500
      
      # 統計
      t.integer :duration_seconds
      t.integer :tables_count
      t.integer :records_count
      
      # エラー情報
      t.text :error_message
      
      # タイムスタンプ
      t.datetime :started_at, null: false
      t.datetime :completed_at
    end
    
    # 手動インデックス
    add_index :backups, :backup_type
    add_index :backups, :status
    add_index :backups, :started_at
    
    # 制約
    add_check_constraint :backups, 
                        "backup_type IN ('full', 'incremental', 'database', 'media')",
                        name: 'backups_valid_type'
    add_check_constraint :backups, 
                        "status IN ('running', 'completed', 'failed')",
                        name: 'backups_valid_status'
  end
end
