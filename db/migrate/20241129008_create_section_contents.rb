class CreateSectionContents < ActiveRecord::Migration[8.0]
  def change
    create_table :section_contents do |t|
      # Section reference
      t.references :portfolio_section, null: false, foreign_key: true
      
      # Content organization
      t.string :content_type, null: false
      t.string :key, null: false, limit: 100
      t.text :title
      t.text :subtitle
      
      # Content data (JSONB for flexibility)
      t.jsonb :content_data, null: false, default: {}
      t.jsonb :settings, default: {}
      
      # Ordering and visibility
      t.integer :sort_order, default: 0, null: false
      t.boolean :visible, default: true, null: false
      
      # Responsive design data
      t.jsonb :responsive_settings, default: {}
      t.jsonb :mobile_content, default: {}
      
      # SEO and metadata
      t.string :anchor_id, limit: 50
      t.jsonb :schema_markup, default: {}
      
      # Versioning
      t.integer :version, default: 1, null: false
      t.references :previous_version, null: true, foreign_key: { to_table: :section_contents }
      
      # Metadata
      t.references :last_edited_by, null: true, foreign_key: { to_table: :admin_users }
      t.text :edit_notes
      
      t.timestamps null: false
    end

    # Indexes
    add_index :section_contents, :content_type
    add_index :section_contents, :key
    add_index :section_contents, :sort_order
    add_index :section_contents, :visible
    add_index :section_contents, :anchor_id
    add_index :section_contents, :version
    
    # Composite indexes
    add_index :section_contents, [:portfolio_section_id, :sort_order], name: 'index_section_contents_section_sort'
    add_index :section_contents, [:portfolio_section_id, :visible, :sort_order], name: 'index_section_contents_visible_sort'
    add_index :section_contents, [:portfolio_section_id, :key], unique: true, name: 'index_section_contents_section_key'
    add_index :section_contents, [:content_type, :visible], name: 'index_section_contents_type_visible'
    
    # JSONB indexes for content search
    add_index :section_contents, :content_data, using: :gin, name: 'index_section_contents_content_data_gin'
    add_index :section_contents, :settings, using: :gin, name: 'index_section_contents_settings_gin'
    
    # Full-text search on title/subtitle
    add_index :section_contents, :title, opclass: :gin_trgm_ops, using: :gin, name: 'index_section_contents_title_trgm'
    
    # Constraints
    add_check_constraint :section_contents, "content_type IN ('text', 'image', 'video', 'gallery', 'timeline', 'skills', 'testimonial', 'contact_info', 'social_links', 'custom')", name: 'section_contents_valid_type'
    add_check_constraint :section_contents, "length(key) >= 1", name: 'section_contents_key_not_empty'
    add_check_constraint :section_contents, "key ~ '^[a-z0-9_-]+$'", name: 'section_contents_key_format'
    add_check_constraint :section_contents, "anchor_id ~ '^[a-z0-9_-]+$' OR anchor_id IS NULL", name: 'section_contents_anchor_id_format'
    add_check_constraint :section_contents, "version >= 1", name: 'section_contents_version_positive'
    add_check_constraint :section_contents, "sort_order >= 0", name: 'section_contents_sort_order_positive'
    add_check_constraint :section_contents, "previous_version_id != id", name: 'section_contents_no_self_reference'
  end
end