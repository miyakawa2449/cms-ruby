class CreateBackups < ActiveRecord::Migration[8.0]
  def change
    create_table :backups do |t|
      # Backup identification
      t.string :name, null: false, limit: 100
      t.string :backup_type, null: false
      t.text :description
      
      # Backup scope
      t.json :included_tables, default: []
      t.json :excluded_tables, default: []
      t.boolean :include_uploads, default: true, null: false
      
      # File information
      t.string :filename, null: false, limit: 255
      t.string :file_path, limit: 500
      t.bigint :file_size
      t.string :file_hash, limit: 64
      t.string :compression_type, default: 'gzip'
      
      # Storage information
      t.string :storage_type, default: 'local', null: false
      t.string :storage_location, limit: 500
      t.string :s3_bucket
      t.string :s3_key
      
      # Backup metadata
      t.json :backup_stats, default: {}
      t.integer :total_records, default: 0
      t.decimal :database_size_mb, precision: 10, scale: 2
      t.decimal :uploads_size_mb, precision: 10, scale: 2
      
      # Timing information
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :duration_seconds
      
      # Status and error tracking
      t.string :status, default: 'pending', null: false
      t.text :error_message
      t.text :log_output
      t.integer :exit_code
      
      # Scheduled backup information
      t.boolean :scheduled, default: false, null: false
      t.string :schedule_frequency
      t.datetime :next_scheduled_at
      
      # Retention and cleanup
      t.datetime :expires_at
      t.boolean :auto_delete, default: true, null: false
      t.integer :retention_days, default: 30
      
      # Verification
      t.boolean :verified, default: false, null: false
      t.datetime :verified_at
      t.text :verification_notes
      
      # Restore information
      t.boolean :restorable, default: true, null: false
      t.integer :restore_count, default: 0, null: false
      t.datetime :last_restored_at
      
      # Created by
      t.references :created_by, null: true, foreign_key: { to_table: :admin_users }
      
      # Notification settings
      t.boolean :notify_on_completion, default: false, null: false
      t.boolean :notify_on_error, default: true, null: false
      
      t.timestamps null: false
    end

    # Indexes
    add_index :backups, :name
    add_index :backups, :backup_type
    add_index :backups, :filename, unique: true
    add_index :backups, :file_hash
    add_index :backups, :storage_type
    add_index :backups, :status
    add_index :backups, :scheduled
    add_index :backups, :verified
    add_index :backups, :restorable
    add_index :backups, :created_by_id
    add_index :backups, :started_at
    add_index :backups, :completed_at
    add_index :backups, :expires_at
    add_index :backups, :next_scheduled_at
    add_index :backups, :last_restored_at
    add_index :backups, :created_at
    
    # Composite indexes
    add_index :backups, [:backup_type, :status], name: 'index_backups_type_status'
    add_index :backups, [:scheduled, :next_scheduled_at], name: 'index_backups_scheduled'
    add_index :backups, [:status, :completed_at], name: 'index_backups_status_completed'
    add_index :backups, [:expires_at, :auto_delete], name: 'index_backups_cleanup'
    add_index :backups, [:verified, :restorable, :completed_at], name: 'index_backups_usable'
    add_index :backups, [:storage_type, :storage_location], name: 'index_backups_storage'
    
    # Performance indexes
    add_index :backups, [:status, :created_at], where: "scheduled = true", name: 'index_backups_scheduled_status'
    add_index :backups, [:expires_at], where: "auto_delete = true AND expires_at < NOW()", name: 'index_backups_expired'
    add_index :backups, [:file_size, :completed_at], where: "status = 'completed'", name: 'index_backups_size_completed'
    
    # JSONB indexes
    add_index :backups, :backup_stats, using: :gin, name: 'index_backups_stats_gin'
    add_index :backups, :included_tables, using: :gin, name: 'index_backups_included_tables_gin'
    
    # Full-text search
    add_index :backups, :name, opclass: :gin_trgm_ops, using: :gin, name: 'index_backups_name_trgm'
    add_index :backups, :description, opclass: :gin_trgm_ops, using: :gin, name: 'index_backups_description_trgm'
    
    # Constraints
    add_check_constraint :backups, "backup_type IN ('full', 'incremental', 'schema', 'data', 'uploads')", name: 'backups_valid_type'
    add_check_constraint :backups, "storage_type IN ('local', 's3', 'ftp', 'sftp')", name: 'backups_valid_storage_type'
    add_check_constraint :backups, "status IN ('pending', 'running', 'completed', 'failed', 'cancelled')", name: 'backups_valid_status'
    add_check_constraint :backups, "compression_type IN ('gzip', 'bzip2', 'xz', 'none')", name: 'backups_valid_compression'
    add_check_constraint :backups, "schedule_frequency IN ('hourly', 'daily', 'weekly', 'monthly') OR schedule_frequency IS NULL", name: 'backups_valid_frequency'
    add_check_constraint :backups, "length(name) >= 3", name: 'backups_name_length'
    add_check_constraint :backups, "file_size >= 0 OR file_size IS NULL", name: 'backups_file_size_positive'
    add_check_constraint :backups, "total_records >= 0", name: 'backups_total_records_positive'
    add_check_constraint :backups, "database_size_mb >= 0 OR database_size_mb IS NULL", name: 'backups_database_size_positive'
    add_check_constraint :backups, "uploads_size_mb >= 0 OR uploads_size_mb IS NULL", name: 'backups_uploads_size_positive'
    add_check_constraint :backups, "duration_seconds >= 0 OR duration_seconds IS NULL", name: 'backups_duration_positive'
    add_check_constraint :backups, "retention_days >= 1", name: 'backups_retention_positive'
    add_check_constraint :backups, "restore_count >= 0", name: 'backups_restore_count_positive'
    add_check_constraint :backups, "exit_code >= 0 OR exit_code IS NULL", name: 'backups_exit_code_positive'
    
    # Status-specific constraints
    add_check_constraint :backups, "(status = 'completed' AND completed_at IS NOT NULL) OR (status != 'completed')", name: 'backups_completed_date_required'
    add_check_constraint :backups, "(scheduled = true AND schedule_frequency IS NOT NULL) OR (scheduled = false)", name: 'backups_scheduled_frequency_required'
  end
end