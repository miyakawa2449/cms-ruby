class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, default: 'string'
      t.string :category, null: false
      t.text :description
      t.boolean :is_sensitive, default: false
      t.jsonb :json_value, default: {}
      
      t.timestamps
    end
    
    add_index :settings, :key, unique: true
    add_index :settings, :category
    add_index :settings, :json_value, using: :gin
    
    # 制約
    add_check_constraint :settings, 
                        "value_type IN ('string', 'integer', 'boolean', 'jsonb')",
                        name: 'settings_valid_value_type'
  end
end
