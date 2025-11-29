class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false, limit: 50
      t.string :slug, null: false, limit: 50
      t.text :description
      t.string :color, limit: 7
      t.string :icon
      
      # Statistics
      t.integer :articles_count, default: 0, null: false
      t.integer :usage_count, default: 0, null: false
      
      # SEO fields
      t.string :meta_title, limit: 60
      t.text :meta_description, limit: 160
      
      # Metadata
      t.boolean :featured, default: false, null: false
      t.boolean :visible, default: true, null: false
      t.integer :sort_order, default: 0, null: false
      
      t.timestamps null: false
    end

    # Indexes
    add_index :tags, :name, unique: true
    add_index :tags, :slug, unique: true
    add_index :tags, :articles_count
    add_index :tags, :usage_count
    add_index :tags, :featured
    add_index :tags, :visible
    add_index :tags, [:visible, :sort_order], name: 'index_tags_visible_sorted'
    add_index :tags, [:featured, :visible, :articles_count], name: 'index_tags_featured_active'
    
    # Full-text search index
    add_index :tags, :name, opclass: :gin_trgm_ops, using: :gin, name: 'index_tags_name_trgm'
    
    # Constraints
    add_check_constraint :tags, "length(name) >= 2", name: 'tags_name_length'
    add_check_constraint :tags, "slug ~ '^[a-z0-9_-]+$'", name: 'tags_slug_format'
    add_check_constraint :tags, "color ~ '^#[0-9A-Fa-f]{6}$' OR color IS NULL", name: 'tags_color_format'
    add_check_constraint :tags, "articles_count >= 0", name: 'tags_articles_count_positive'
    add_check_constraint :tags, "usage_count >= 0", name: 'tags_usage_count_positive'
  end
end