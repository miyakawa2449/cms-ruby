class CreateAdminPathHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_path_histories do |t|
      t.string :old_path
      t.string :new_path
      t.string :change_type
      t.references :admin_user, null: false, foreign_key: true
      t.string :ip_address
      t.text :reason
      t.datetime :notified_at

      t.timestamps
    end
  end
end
