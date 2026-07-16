# frozen_string_literal: true

# S1-7 P0-4: 週次セキュリティレポートのincidents集計を実データ化するため、
# これまでRails.loggerにしか出ていなかったセキュリティイベントをDBに永続化する
class CreateSecurityEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :security_events do |t|
      t.string :event_type, null: false
      t.string :email
      t.string :ip
      t.string :path
      t.string :user_agent
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :security_events, [ :event_type, :occurred_at ]
    add_index :security_events, :occurred_at
  end
end
