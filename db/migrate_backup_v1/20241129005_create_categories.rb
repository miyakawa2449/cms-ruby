class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false, limit: 50
      t.string :slug, null: false, limit: 50
      t.text :description
      t.string :color, limit: 7
      t.string :icon
      
      # Hierarchy support (self-referential)
      t.references :parent, null: true, foreign_key: { to_table: :categories }
      t.integer :sort_order, default: 0, null: false
      t.integer :depth, default: 0, null: false
      t.string :path, limit: 500
      
      # Statistics
      t.integer :articles_count, default: 0, null: false
      t.integer :children_count, default: 0, null: false
      
      # SEO fields
      t.string :meta_title, limit: 60
      t.text :meta_description, limit: 160
      
      # Metadata
      t.boolean :featured, default: false, null: false
      t.boolean :visible, default: true, null: false
      t.boolean :show_in_navigation, default: true, null: false
      
      t.timestamps null: false
    end

    # Indexes
    add_index :categories, :name, unique: true
    add_index :categories, :slug, unique: true
    add_index :categories, :depth
    add_index :categories, :path, using: :gin, opclass: :gin_trgm_ops
    add_index :categories, :articles_count
    add_index :categories, :featured
    add_index :categories, :visible
    add_index :categories, :show_in_navigation
    
    # Composite indexes for hierarchy queries
    add_index :categories, [:parent_id, :sort_order], name: 'index_categories_parent_sort'
    add_index :categories, [:visible, :parent_id, :sort_order], name: 'index_categories_visible_hierarchy'
    add_index :categories, [:show_in_navigation, :visible, :sort_order], name: 'index_categories_navigation'
    add_index :categories, [:featured, :visible, :articles_count], name: 'index_categories_featured_active'
    
    # Full-text search index
    add_index :categories, :name, opclass: :gin_trgm_ops, using: :gin, name: 'index_categories_name_trgm'
    
    # Constraints
    add_check_constraint :categories, "length(name) >= 2", name: 'categories_name_length'
    add_check_constraint :categories, "slug ~ '^[a-z0-9_-]+$'", name: 'categories_slug_format'
    add_check_constraint :categories, "color ~ '^#[0-9A-Fa-f]{6}$' OR color IS NULL", name: 'categories_color_format'
    add_check_constraint :categories, "depth >= 0 AND depth <= 2", name: 'categories_depth_range'
    add_check_constraint :categories, "articles_count >= 0", name: 'categories_articles_count_positive'
    add_check_constraint :categories, "children_count >= 0", name: 'categories_children_count_positive'
    add_check_constraint :categories, "parent_id != id", name: 'categories_no_self_reference'
    
    # Prevent circular references (depth-based constraint)
    add_check_constraint :categories, "(parent_id IS NULL AND depth = 0) OR (parent_id IS NOT NULL AND depth > 0)", name: 'categories_depth_consistency'
  end
end