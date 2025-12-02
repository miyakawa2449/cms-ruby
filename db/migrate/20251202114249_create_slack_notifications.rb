class CreateSlackNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :slack_notifications do |t|
      # 通知情報
      t.string :notification_type, null: false, limit: 50
      t.bigint :reference_id
      t.string :reference_type, limit: 50
      
      # Slack情報
      t.string :webhook_url, limit: 500
      t.string :channel, limit: 100
      
      # 送信内容（JSONB統一）
      t.jsonb :payload, null: false, default: {}
      
      # ステータス
      t.string :status, default: 'pending', null: false
      t.text :error_message
      t.integer :retry_count, default: 0
      
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
      t.datetime :sent_at
    end
    
    # 手動インデックス
    add_index :slack_notifications, :notification_type
    add_index :slack_notifications, :status
    add_index :slack_notifications, :created_at
    add_index :slack_notifications, :payload, using: :gin
    
    # 制約
    add_check_constraint :slack_notifications, 
                        "notification_type IN ('contact', 'article_published', 'comment', 'error')",
                        name: 'slack_notifications_valid_type'
  end
end
