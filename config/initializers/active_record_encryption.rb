# Active Record Encryption Configuration
# 既存の平文データとの互換性を保つための設定

Rails.application.configure do
  # 既存の暗号化されていないデータを読み取り可能にする
  # これにより、暗号化導入前のデータも正常に表示される
  config.active_record.encryption.support_unencrypted_data = true

  # 暗号化されていないデータへの書き込みを許可（移行期間中のみ）
  # 新規データは暗号化されるが、既存データの更新時にエラーにならない
  config.active_record.encryption.extend_queries = true
end
