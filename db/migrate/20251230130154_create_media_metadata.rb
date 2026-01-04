class CreateMediaMetadata < ActiveRecord::Migration[8.1]
  def change
    create_table :media_metadata do |t|
      # Use index: { unique: true } instead of separate add_index
      t.references :blob, foreign_key: { to_table: :active_storage_blobs }, null: false, index: { unique: true }
      t.string :alt_text
      t.integer :width
      t.integer :height
      t.string :mime_type, index: true
      t.bigint :file_size
      t.jsonb :variants, default: {}
      t.integer :usage_count, default: 0, index: true

      t.timestamps
    end

    add_index :media_metadata, :created_at
  end
end
