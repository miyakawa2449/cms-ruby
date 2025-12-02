class CreateAdminUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_users do |t|
      # Devise columns
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      
      # Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      
      # Rememberable
      t.datetime :remember_created_at
      
      # Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      
      # Lockable
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at
      
      # Custom fields for portfolio CMS
      t.string :name, null: false
      t.string :avatar_url
      t.string :role, default: 'author', null: false
      t.string :status, default: 'active', null: false
      
      # Two-factor authentication
      t.string :otp_secret
      t.boolean :otp_required_for_login, default: false, null: false
      
      # Security tracking
      t.string :session_token
      t.datetime :last_activity_at
      t.inet :last_ip_address
      
      # Admin-specific fields
      t.json :permissions, default: {}
      t.json :settings, default: {}
      t.text :notes
      t.string :timezone, default: 'Asia/Tokyo'
      t.string :language, default: 'ja'
      t.string :api_token
      t.datetime :api_token_generated_at
      t.datetime :confirmed_at
      
      t.timestamps null: false
    end

    # Devise indexes
    add_index :admin_users, :email,                unique: true
    add_index :admin_users, :reset_password_token, unique: true
    add_index :admin_users, :unlock_token,         unique: true
    add_index :admin_users, :session_token,        unique: true
    
    # Custom indexes
    add_index :admin_users, :role
    add_index :admin_users, :status
    add_index :admin_users, :last_activity_at
    add_index :admin_users, :otp_required_for_login
    add_index :admin_users, :api_token, unique: true
    
    # Constraints
    add_check_constraint :admin_users, "role IN ('admin', 'editor', 'author', 'viewer')", name: 'admin_users_valid_role'
    add_check_constraint :admin_users, "status IN ('active', 'inactive', 'suspended')", name: 'admin_users_valid_status'
    add_check_constraint :admin_users, "length(name) >= 2", name: 'admin_users_name_length'
  end
end