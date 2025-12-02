class CreateSlackNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :slack_notifications do |t|
      # Notification type and content
      t.string :notification_type, null: false
      t.string :event_type, null: false
      t.text :message_text, null: false
      t.json :message_payload, default: {}
      
      # Target information
      t.string :channel, null: false
      t.string :webhook_url
      
      # Reference to related objects
      t.string :notifiable_type
      t.bigint :notifiable_id
      t.references :triggered_by, null: true, foreign_key: { to_table: :admin_users }
      
      # Delivery status
      t.string :status, default: 'pending', null: false
      t.text :error_message
      t.json :response_data, default: {}
      t.integer :retry_count, default: 0, null: false
      t.datetime :scheduled_for
      t.datetime :sent_at
      
      # Priority and settings
      t.integer :priority, default: 3, null: false
      t.boolean :urgent, default: false, null: false
      t.json :notification_settings, default: {}
      
      # Rate limiting
      t.string :rate_limit_key
      t.datetime :rate_limit_reset_at
      
      t.timestamps null: false
    end

    # Indexes
    add_index :slack_notifications, :notification_type
    add_index :slack_notifications, :event_type
    add_index :slack_notifications, :channel
    add_index :slack_notifications, :status
    add_index :slack_notifications, :priority
    add_index :slack_notifications, :urgent
    add_index :slack_notifications, :retry_count
    add_index :slack_notifications, :scheduled_for
    add_index :slack_notifications, :sent_at
    add_index :slack_notifications, :created_at
    
    # Polymorphic indexes
    add_index :slack_notifications, [:notifiable_type, :notifiable_id], name: 'index_slack_notifications_notifiable'
    
    # Composite indexes
    add_index :slack_notifications, [:status, :scheduled_for], name: 'index_slack_notifications_status_scheduled'
    add_index :slack_notifications, [:status, :retry_count, :created_at], name: 'index_slack_notifications_retry'
    add_index :slack_notifications, [:notification_type, :created_at], name: 'index_slack_notifications_type_date'
    add_index :slack_notifications, [:channel, :sent_at], name: 'index_slack_notifications_channel_sent'
    add_index :slack_notifications, [:priority, :urgent, :status], name: 'index_slack_notifications_priority_queue'
    
    # Performance indexes
    add_index :slack_notifications, [:status, :created_at], where: "retry_count < 3", name: 'index_slack_notifications_retryable'
    add_index :slack_notifications, [:urgent, :status, :scheduled_for], where: "status IN ('pending', 'failed')", name: 'index_slack_notifications_urgent_pending'
    
    # Rate limiting
    add_index :slack_notifications, [:rate_limit_key, :created_at], name: 'index_slack_notifications_rate_limit'
    
    # JSONB indexes
    add_index :slack_notifications, :message_payload, using: :gin, name: 'index_slack_notifications_payload_gin'
    add_index :slack_notifications, :notification_settings, using: :gin, name: 'index_slack_notifications_settings_gin'
    
    # Constraints
    add_check_constraint :slack_notifications, "notification_type IN ('article_published', 'comment_posted', 'contact_received', 'error_occurred', 'backup_completed', 'system_alert', 'custom')", name: 'slack_notifications_valid_type'
    add_check_constraint :slack_notifications, "event_type IN ('create', 'update', 'delete', 'publish', 'error', 'warning', 'info', 'success')", name: 'slack_notifications_valid_event'
    add_check_constraint :slack_notifications, "status IN ('pending', 'sent', 'failed', 'cancelled', 'scheduled')", name: 'slack_notifications_valid_status'
    add_check_constraint :slack_notifications, "priority >= 1 AND priority <= 5", name: 'slack_notifications_priority_range'
    add_check_constraint :slack_notifications, "retry_count >= 0 AND retry_count <= 5", name: 'slack_notifications_retry_count_range'
    add_check_constraint :slack_notifications, "length(message_text) >= 1", name: 'slack_notifications_message_not_empty'
    add_check_constraint :slack_notifications, "channel ~ '^#[a-z0-9_-]+$'", name: 'slack_notifications_channel_format'
    
    # Polymorphic constraints
    add_check_constraint :slack_notifications, "(notifiable_type IS NULL AND notifiable_id IS NULL) OR (notifiable_type IS NOT NULL AND notifiable_id IS NOT NULL)", name: 'slack_notifications_notifiable_consistency'
  end
end