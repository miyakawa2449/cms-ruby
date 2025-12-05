class CreateSlackNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :slack_notifications do |t|
      t.string :notification_type
      t.bigint :reference_id
      t.string :reference_type
      t.string :webhook_url
      t.string :channel
      t.text :payload
      t.string :status, default: 'pending'
      t.text :error_message
      t.integer :retry_count, default: 0
      t.timestamp :sent_at

      t.timestamps
    end
    
    add_index :slack_notifications, :notification_type
    add_index :slack_notifications, :status
    add_index :slack_notifications, :created_at
  end
end
