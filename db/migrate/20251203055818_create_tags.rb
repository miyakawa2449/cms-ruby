class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, limit: 50, null: false
      t.string :slug, limit: 50, null: false
      t.integer :article_count, default: 0

      t.timestamps
    end

    add_index :tags, :name, unique: true
    add_index :tags, :slug, unique: true
  end
end
