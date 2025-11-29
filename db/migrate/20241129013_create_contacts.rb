class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      # Contact information
      t.string :name, null: false, limit: 100
      t.string :email, null: false, limit: 255
      t.string :company, limit: 100
      t.string :phone, limit: 20
      t.string :website, limit: 255
      
      # Message details
      t.string :subject, null: false, limit: 200
      t.text :message, null: false
      t.string :inquiry_type, default: 'general'
      t.string :budget_range
      t.string :timeline
      
      # Technical information
      t.inet :ip_address
      t.string :user_agent, limit: 500
      t.string :referrer, limit: 500
      t.json :browser_info, default: {}
      
      # Processing status
      t.string :status, default: 'new', null: false
      t.text :internal_notes
      t.references :assigned_to, null: true, foreign_key: { to_table: :admin_users }
      t.datetime :responded_at
      
      # Spam protection
      t.string :captcha_token
      t.decimal :spam_score, precision: 5, scale: 4, default: 0.0
      t.json :spam_flags, default: []
      t.boolean :verified, default: false, null: false
      
      # Notification tracking
      t.boolean :slack_notified, default: false, null: false
      t.boolean :email_notified, default: false, null: false
      t.datetime :slack_notified_at
      t.datetime :email_notified_at
      
      # Follow-up
      t.boolean :requires_followup, default: false, null: false
      t.datetime :followup_at
      t.integer :priority, default: 1, null: false
      
      # GDPR compliance
      t.boolean :gdpr_consent, default: false, null: false
      t.boolean :marketing_consent, default: false, null: false
      t.datetime :data_retention_until
      
      t.timestamps null: false
    end

    # Indexes
    add_index :contacts, :email
    add_index :contacts, :company
    add_index :contacts, :status
    add_index :contacts, :inquiry_type
    add_index :contacts, :assigned_to_id
    add_index :contacts, :spam_score
    add_index :contacts, :verified
    add_index :contacts, :requires_followup
    add_index :contacts, :priority
    add_index :contacts, :ip_address
    add_index :contacts, :created_at
    add_index :contacts, :responded_at
    add_index :contacts, :followup_at
    
    # Composite indexes
    add_index :contacts, [:status, :priority, :created_at], name: 'index_contacts_status_priority_date'
    add_index :contacts, [:assigned_to_id, :status], name: 'index_contacts_assigned_status'
    add_index :contacts, [:requires_followup, :followup_at], name: 'index_contacts_followup'
    add_index :contacts, [:spam_score, :verified], name: 'index_contacts_spam_verification'
    add_index :contacts, [:inquiry_type, :created_at], name: 'index_contacts_type_date'
    add_index :contacts, [:email, :created_at], name: 'index_contacts_email_date'
    
    # Full-text search
    add_index :contacts, :name, opclass: :gin_trgm_ops, using: :gin, name: 'index_contacts_name_trgm'
    add_index :contacts, :subject, opclass: :gin_trgm_ops, using: :gin, name: 'index_contacts_subject_trgm'
    add_index :contacts, :message, opclass: :gin_trgm_ops, using: :gin, name: 'index_contacts_message_trgm'
    
    # Performance indexes
    add_index :contacts, [:status, :created_at], where: "verified = true", name: 'index_contacts_verified_status'
    add_index :contacts, [:priority, :created_at], where: "status IN ('new', 'in_progress')", name: 'index_contacts_active_priority'
    
    # Constraints
    add_check_constraint :contacts, "status IN ('new', 'in_progress', 'completed', 'spam', 'archived')", name: 'contacts_valid_status'
    add_check_constraint :contacts, "inquiry_type IN ('general', 'project', 'consultation', 'partnership', 'media', 'support')", name: 'contacts_valid_inquiry_type'
    add_check_constraint :contacts, "priority >= 1 AND priority <= 5", name: 'contacts_priority_range'
    add_check_constraint :contacts, "spam_score >= 0 AND spam_score <= 1", name: 'contacts_spam_score_range'
    add_check_constraint :contacts, "length(name) >= 2", name: 'contacts_name_length'
    add_check_constraint :contacts, "length(message) >= 10", name: 'contacts_message_length'
    add_check_constraint :contacts, "email ~ '^[^@]+@[^@]+\.[^@]+$'", name: 'contacts_email_format'
    add_check_constraint :contacts, "phone ~ '^[+]?[0-9\s\-\(\)]+$' OR phone IS NULL", name: 'contacts_phone_format'
    
    # GDPR constraints
    add_check_constraint :contacts, "gdpr_consent = true", name: 'contacts_gdpr_consent_required'
  end
end