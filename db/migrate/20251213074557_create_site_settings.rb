class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :key, null: false
      t.text :value
      t.text :description
      t.string :setting_type, default: 'text'

      t.timestamps
    end
    
    add_index :site_settings, :key, unique: true
  end
end
