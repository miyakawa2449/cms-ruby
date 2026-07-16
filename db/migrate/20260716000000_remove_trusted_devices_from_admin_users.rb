class RemoveTrustedDevicesFromAdminUsers < ActiveRecord::Migration[8.1]
  # 「デバイス信頼（30日OTPスキップ）」機能の削除（監査M-3）。
  # この機能はverify画面が到達不能だったため一度も動作しておらず、
  # カラムには実データが存在しない
  def change
    remove_column :admin_users, :trusted_devices, :jsonb, default: []
  end
end
