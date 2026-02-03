# frozen_string_literal: true

class CreateSecurityReports < ActiveRecord::Migration[8.1]
  def change
    create_table :security_reports do |t|
      t.integer :report_type, null: false
      t.integer :status, null: false, default: 0
      t.datetime :period_start, null: false
      t.datetime :period_end, null: false
      t.jsonb :data, default: {}
      t.datetime :generated_at

      t.timestamps
    end

    add_index :security_reports, :report_type
    add_index :security_reports, :status
    add_index :security_reports, :generated_at
  end
end
