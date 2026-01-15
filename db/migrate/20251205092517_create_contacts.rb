class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :email
      t.string :subject
      t.text :message
      t.inet :ip_address
      t.text :user_agent
      t.string :referrer
      t.string :status, default: 'unread'
      t.references :assigned_to, null: true, foreign_key: { to_table: :admin_users }
      t.decimal :spam_score, precision: 3, scale: 2
      t.boolean :is_spam, default: false
      t.timestamp :replied_at
      t.text :notes

      t.timestamps
    end

    add_index :contacts, :email
    add_index :contacts, :status
    add_index :contacts, :created_at
  end
end
