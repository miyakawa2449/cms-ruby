class AddCustomFieldsToAdminUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_users, :name, :string, null: false
    add_column :admin_users, :avatar_url, :string
    add_column :admin_users, :role, :string, default: 'author'
    add_column :admin_users, :settings, :jsonb, default: {}
    add_column :admin_users, :api_token, :string
    add_column :admin_users, :otp_required_for_login, :boolean, default: false
    
    # 手動インデックス（複合・特殊用途のみ）
    add_index :admin_users, :role
    add_index :admin_users, :api_token, unique: true
    
    # 制約
    add_check_constraint :admin_users, "role IN ('admin', 'editor', 'author', 'viewer')", 
                        name: 'admin_users_valid_role'
  end
end
