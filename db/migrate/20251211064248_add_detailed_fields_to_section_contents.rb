class AddDetailedFieldsToSectionContents < ActiveRecord::Migration[8.1]
  def change
    add_column :section_contents, :main_message, :text
    add_column :section_contents, :sub_message, :text
    add_column :section_contents, :career_description, :text
    add_column :section_contents, :cta_primary_text, :string
    add_column :section_contents, :cta_primary_url, :string
    add_column :section_contents, :cta_secondary_text, :string
    add_column :section_contents, :cta_secondary_url, :string
    add_column :section_contents, :profile_text, :text
    add_column :section_contents, :frontend_skills, :text
    add_column :section_contents, :backend_skills, :text
    add_column :section_contents, :core_skills, :text
    add_column :section_contents, :experience_text, :text
  end
end
