class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false, limit: 100
      t.text :value
      t.string :value_type, default: 'string', null: false
      t.string :category, null: false, default: 'general'
      t.text :description
      t.boolean :encrypted, default: false, null: false
      t.boolean :system_setting, default: false, null: false
      
      # Validation
      t.json :validation_rules, default: {}
      t.text :allowed_values
      
      # Metadata
      t.string :label
      t.string :input_type, default: 'text'
      t.integer :sort_order, default: 0
      t.boolean :visible_in_ui, default: true, null: false
      
      t.timestamps null: false
    end

    # Indexes
    add_index :settings, :key, unique: true
    add_index :settings, :category
    add_index :settings, :system_setting
    add_index :settings, :encrypted
    add_index :settings, [:category, :sort_order], name: 'index_settings_category_sort'
    add_index :settings, [:visible_in_ui, :category, :sort_order], name: 'index_settings_ui_display'
    
    # Constraints
    add_check_constraint :settings, "value_type IN ('string', 'integer', 'boolean', 'json', 'array')", name: 'settings_valid_value_type'
    add_check_constraint :settings, "category IN ('general', 'seo', 'ai', 'security', 'integrations', 'email', 'backup', 'monitoring')", name: 'settings_valid_category'
    add_check_constraint :settings, "input_type IN ('text', 'textarea', 'password', 'select', 'checkbox', 'radio', 'number', 'email', 'url')", name: 'settings_valid_input_type'
    add_check_constraint :settings, "length(key) >= 2", name: 'settings_key_length'
    add_check_constraint :settings, "key ~ '^[a-z0-9_]+$'", name: 'settings_key_format'
  end
end