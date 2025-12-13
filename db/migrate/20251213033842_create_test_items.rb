class CreateTestItems < ActiveRecord::Migration[8.0]
  def change
    create_table :test_items do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
  end
end
