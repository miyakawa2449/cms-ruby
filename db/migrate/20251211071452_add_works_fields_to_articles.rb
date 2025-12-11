class AddWorksFieldsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :work_type, :string
    add_column :articles, :github_url, :string
    add_column :articles, :demo_url, :string
    add_column :articles, :tech_stack, :text
  end
end
