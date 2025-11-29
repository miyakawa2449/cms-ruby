class CreatePortfolioSections < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_sections do |t|
      t.string :name, null: false, limit: 100
      t.string :slug, null: false, limit: 50
      t.text :description
      t.integer :sort_order, null: false, default: 0
      t.boolean :visible, default: true, null: false
      
      # Section configuration
      t.string :section_type, null: false
      t.string :template, null: false, default: 'default'
      t.json :settings, default: {}
      
      # Metadata
      t.string :icon
      t.string :color_theme, default: 'default'
      t.boolean :show_in_navigation, default: true, null: false
      
      # SEO fields
      t.string :meta_title, limit: 60
      t.text :meta_description, limit: 160
      t.string :og_image_url
      
      t.timestamps null: false
    end

    # Indexes
    add_index :portfolio_sections, :slug, unique: true
    add_index :portfolio_sections, :sort_order
    add_index :portfolio_sections, :visible
    add_index :portfolio_sections, :section_type
    add_index :portfolio_sections, :show_in_navigation
    
    # Composite index for frontend queries
    add_index :portfolio_sections, [:visible, :sort_order], name: 'index_portfolio_sections_active'
    add_index :portfolio_sections, [:visible, :show_in_navigation, :sort_order], name: 'index_portfolio_sections_navigation'
    
    # Constraints
    add_check_constraint :portfolio_sections, "section_type IN ('hero', 'about', 'services', 'story', 'works', 'blog', 'contact', 'custom')", name: 'portfolio_sections_valid_type'
    add_check_constraint :portfolio_sections, "sort_order >= 0", name: 'portfolio_sections_sort_order_positive'
    add_check_constraint :portfolio_sections, "length(name) >= 1", name: 'portfolio_sections_name_not_empty'
    add_check_constraint :portfolio_sections, "slug ~ '^[a-z0-9_-]+$'", name: 'portfolio_sections_slug_format'
  end
end