class CreateMediaFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :media_files do |t|
      # Basic file information
      t.string :filename, null: false, limit: 255
      t.string :original_filename, null: false, limit: 255
      t.string :content_type, null: false, limit: 100
      t.bigint :file_size, null: false
      t.string :file_hash, null: false, limit: 64
      
      # Storage information
      t.string :storage_type, default: 'local', null: false
      t.string :storage_path, null: false, limit: 500
      t.string :public_url, limit: 500
      t.string :cdn_url, limit: 500
      
      # Image-specific fields
      t.integer :width
      t.integer :height
      t.string :image_format
      t.json :exif_data, default: {}
      
      # Variants and processing
      t.json :variants, default: {}
      t.boolean :optimized, default: false, null: false
      t.datetime :optimized_at
      t.bigint :original_file_size
      t.decimal :compression_ratio, precision: 5, scale: 4
      
      # Organization
      t.string :alt_text, limit: 200
      t.text :caption
      t.text :description
      t.json :tags, default: []
      t.string :folder, limit: 100
      
      # Usage tracking
      t.integer :usage_count, default: 0, null: false
      t.datetime :last_used_at
      t.references :uploaded_by, null: false, foreign_key: { to_table: :admin_users }
      
      # Security and access
      t.boolean :public, default: true, null: false
      t.string :access_token, limit: 32
      t.datetime :expires_at
      
      # Metadata
      t.json :metadata, default: {}
      t.text :processing_log
      t.string :status, default: 'uploaded', null: false
      
      t.timestamps null: false
    end

    # Indexes
    add_index :media_files, :filename
    add_index :media_files, :file_hash, unique: true
    add_index :media_files, :content_type
    add_index :media_files, :storage_type
    add_index :media_files, :image_format
    add_index :media_files, :folder
    add_index :media_files, :usage_count
    add_index :media_files, :last_used_at
    add_index :media_files, :public
    add_index :media_files, :status
    add_index :media_files, :optimized
    add_index :media_files, :expires_at
    add_index :media_files, :created_at
    
    # Composite indexes
    add_index :media_files, [:content_type, :public, :created_at], name: 'index_media_files_type_public_date'
    add_index :media_files, [:folder, :public, :filename], name: 'index_media_files_folder_public_name'
    add_index :media_files, [:uploaded_by_id, :created_at], name: 'index_media_files_uploader_date'
    add_index :media_files, [:usage_count, :last_used_at], name: 'index_media_files_usage'
    add_index :media_files, [:image_format, :optimized, :file_size], name: 'index_media_files_image_optimization'
    
    # Full-text search indexes
    add_index :media_files, :filename, opclass: :gin_trgm_ops, using: :gin, name: 'index_media_files_filename_trgm'
    add_index :media_files, :alt_text, opclass: :gin_trgm_ops, using: :gin, name: 'index_media_files_alt_text_trgm'
    
    # Performance indexes
    add_index :media_files, [:public, :content_type, :created_at], where: "expires_at IS NULL", name: 'index_media_files_active'
    
    # Constraints
    add_check_constraint :media_files, "storage_type IN ('local', 's3', 'cdn')", name: 'media_files_valid_storage_type'
    add_check_constraint :media_files, "status IN ('uploaded', 'processing', 'optimized', 'error')", name: 'media_files_valid_status'
    add_check_constraint :media_files, "content_type ~ '^(image|video|audio|document)/'", name: 'media_files_valid_content_type'
    add_check_constraint :media_files, "file_size > 0", name: 'media_files_file_size_positive'
    add_check_constraint :media_files, "length(filename) >= 1", name: 'media_files_filename_not_empty'
    add_check_constraint :media_files, "usage_count >= 0", name: 'media_files_usage_count_positive'
    add_check_constraint :media_files, "width > 0 OR width IS NULL", name: 'media_files_width_positive'
    add_check_constraint :media_files, "height > 0 OR height IS NULL", name: 'media_files_height_positive'
    add_check_constraint :media_files, "compression_ratio >= 0 AND compression_ratio <= 1 OR compression_ratio IS NULL", name: 'media_files_compression_ratio_range'
    
    # Image-specific constraints
    add_check_constraint :media_files, "(content_type LIKE 'image/%' AND width IS NOT NULL AND height IS NOT NULL) OR content_type NOT LIKE 'image/%'", name: 'media_files_image_dimensions_required'
  end
end