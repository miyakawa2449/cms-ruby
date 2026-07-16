class CreatePasskeyCredentials < ActiveRecord::Migration[8.1]
  # パスキー認証（WebAuthn）用のクレデンシャル保存（S1-6 Phase A）。
  # public_keyは公開鍵のみ（秘密鍵はユーザーのデバイス側にあり、サーバーには来ない）
  def change
    create_table :passkey_credentials do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :nickname, null: false
      t.bigint :sign_count, null: false, default: 0
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :passkey_credentials, :external_id, unique: true
    add_index :passkey_credentials, [ :admin_user_id, :nickname ], unique: true

    # WebAuthnのユーザーハンドル（メールアドレス変更に影響されない安定ID）
    add_column :admin_users, :webauthn_id, :string
  end
end
