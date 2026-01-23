class AddTwoFactorToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    # devise-two-factor 6.x columns (using Active Record encryption)
    add_column :admin_users, :otp_secret, :string
    add_column :admin_users, :consumed_timestep, :integer
    add_column :admin_users, :otp_required_for_login, :boolean, default: false, null: false

    # Backup codes (stored as JSON array of hashed codes)
    add_column :admin_users, :otp_backup_codes, :text, array: true, default: []

    # Additional 2FA tracking columns
    add_column :admin_users, :otp_enabled_at, :datetime
    add_column :admin_users, :trusted_devices, :jsonb, default: []

    add_index :admin_users, :otp_required_for_login
  end
end
