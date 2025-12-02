class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      # 送信者情報
      t.string :name, null: false, limit: 100
      t.string :email, null: false
      t.string :subject, null: false
      t.text :message, null: false
      
      # メタデータ
      t.inet :ip_address
      t.text :user_agent
      t.string :referrer, limit: 500
      
      # ステータス
      t.string :status, default: 'unread', null: false
      
      # 対応情報
      t.references :assigned_to, foreign_key: { to_table: :admin_users }
      t.datetime :replied_at
      t.text :notes
      
      # スパムチェック
      t.decimal :spam_score, precision: 3, scale: 2
      t.boolean :is_spam, default: false
      
      t.timestamps
    end
    
    # 手動インデックス
    add_index :contacts, :email
    add_index :contacts, :status
    add_index :contacts, :created_at
    
    # 制約
    add_check_constraint :contacts, 
                        "status IN ('unread', 'read', 'replied', 'archived')",
                        name: 'contacts_valid_status'
  end
end
