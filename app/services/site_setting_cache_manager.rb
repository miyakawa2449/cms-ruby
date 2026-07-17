class SiteSettingCacheManager
  CACHE_KEY = "site_settings_all".freeze
  CACHE_EXPIRES_IN = 1.hour

  # 共有キャッシュ（本番はsolid_cache）のみに依存する。
  # プロセス内メモ化は禁止: 過去にクラス変数メモ化していた際、設定変更が
  # 他のPumaワーカーへプロセス再起動まで反映されないバグがあった（監査C-9）
  def self.fetch_all_settings
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRES_IN) do
      settings = load_settings_from_db
      ensure_all_settings_present(settings)
      settings
    end
  end

  def self.clear_cache
    Rails.cache.delete(CACHE_KEY)
  end

  def self.load_settings_from_db
    keys = SiteSetting::SETTING_TYPES.keys.map(&:to_s)
    SiteSetting
      .includes(
        :image_value_attachment,
        :image_value_blob,
        :file_value_attachment,
        :file_value_blob
      )
      .where(key: keys)
      .index_by { |setting| setting.key.to_sym }
  end

  def self.ensure_all_settings_present(settings)
    missing_keys = SiteSetting::SETTING_TYPES.keys - settings.keys
    return if missing_keys.empty?

    missing_keys.each do |setting_name|
      config = SiteSetting::SETTING_TYPES[setting_name.to_sym]
      settings[setting_name] = SiteSetting.create!(
        key: config[:key],
        setting_type: config[:type],
        description: config[:description],
        value: config[:default]
      )
    end
  end

  private_class_method :load_settings_from_db, :ensure_all_settings_present
end
