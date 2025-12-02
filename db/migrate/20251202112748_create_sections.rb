class CreateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :sections do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.boolean :is_visible, default: true
      t.integer :position, default: 0
      
      t.timestamps
    end
    
    add_index :sections, :name, unique: true
    add_index :sections, :position
  end
end
