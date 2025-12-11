class AddMyStoryFieldsToSectionContents < ActiveRecord::Migration[8.1]
  def change
    add_column :section_contents, :badge_text, :string
    add_column :section_contents, :main_title, :text
    add_column :section_contents, :sub_title, :text
    add_column :section_contents, :phase1_year, :string
    add_column :section_contents, :phase1_title, :string
    add_column :section_contents, :phase1_description, :text
    add_column :section_contents, :phase1_period, :string
    add_column :section_contents, :phase2_year, :string
    add_column :section_contents, :phase2_title, :string
    add_column :section_contents, :phase2_description, :text
    add_column :section_contents, :phase2_period, :string
    add_column :section_contents, :phase3_year, :string
    add_column :section_contents, :phase3_title, :string
    add_column :section_contents, :phase3_description, :text
    add_column :section_contents, :phase3_period, :string
    add_column :section_contents, :cta_button_text, :string
    add_column :section_contents, :cta_description, :text
  end
end
