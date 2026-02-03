# frozen_string_literal: true

class CreateSecurityScans < ActiveRecord::Migration[8.1]
  def change
    create_table :security_scans do |t|
      t.integer :scan_type, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :raw_results
      t.datetime :scanned_at, null: false
      t.text :error_message

      t.timestamps
    end

    add_index :security_scans, :scan_type
    add_index :security_scans, :status
    add_index :security_scans, :scanned_at
  end
end
