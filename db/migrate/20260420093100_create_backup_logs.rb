class CreateBackupLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :backup_logs do |t|
      t.integer :backup_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.bigint :file_size
      t.text :error_message
      t.string :s3_keys, array: true, default: []

      t.timestamps
    end

    add_index :backup_logs, :backup_type
    add_index :backup_logs, :status
    add_index :backup_logs, :started_at
  end
end
