class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.string :title, limit: 255, null: false
      t.string :slug, limit: 255, null: false
      t.text :content, null: false
      t.text :content_html
      t.text :excerpt
      t.string :status, limit: 50, default: 'draft'
      t.datetime :published_at
      t.string :meta_description, limit: 500
      t.string :meta_keywords, limit: 500
      t.string :og_title, limit: 255
      t.string :og_description, limit: 500

      t.timestamps
    end
    
    add_index :articles, :slug, unique: true
    add_index :articles, :status
    add_index :articles, :published_at
    add_index :articles, [:status, :published_at]
  end
end
