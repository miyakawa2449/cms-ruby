# frozen_string_literal: true

class CreateVulnerabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :vulnerabilities do |t|
      t.references :security_scan, null: false, foreign_key: true
      t.integer :severity, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :file_path
      t.integer :line_number
      t.string :gem_name
      t.string :gem_version
      t.string :cve_id
      t.string :patched_versions
      t.boolean :fixed, default: false
      t.datetime :fixed_at

      t.timestamps
    end

    add_index :vulnerabilities, :severity
    add_index :vulnerabilities, :fixed
    add_index :vulnerabilities, :cve_id
  end
end
