class SiteSettingCacheManager
  CACHE_KEY = "site_settings_all".freeze
  CACHE_EXPIRES_IN = 1.hour

  def self.fetch_all_settings
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRES_IN) do
      SiteSetting::SETTING_TYPES.keys.each_with_object({}) do |setting_name, settings|
        settings[setting_name] = SiteSetting.public_send(setting_name)
      end
    end
  end

  def self.clear_cache
    Rails.cache.delete(CACHE_KEY)
  end

  def self.refresh_cache
    clear_cache
    fetch_all_settings
  end

  # 特定設定のキャッシュキー生成
  def self.setting_cache_key(setting_key)
    "site_setting_#{setting_key}"
  end

  # 個別設定のキャッシュ
  def self.fetch_setting(setting_key, expires_in: CACHE_EXPIRES_IN)
    cache_key = setting_cache_key(setting_key)

    Rails.cache.fetch(cache_key, expires_in: expires_in) do
      setting = SiteSetting.find_by(key: setting_key)
      setting&.get_value
    end
  end

  # 個別設定のキャッシュクリア
  def self.clear_setting_cache(setting_key)
    cache_key = setting_cache_key(setting_key)
    Rails.cache.delete(cache_key)
  end

  # よく使用される設定の事前ロード
  def self.preload_common_settings
    common_settings = %w[site_title site_description favicon og_image]

    common_settings.each do |setting_key|
      fetch_setting(setting_key)
    end
  end

  # キャッシュ統計情報
  def self.cache_stats
    stats = {}

    # 全設定キャッシュ
    stats[:all_settings] = Rails.cache.exist?(CACHE_KEY)

    # 個別設定キャッシュ
    SiteSetting::SETTING_TYPES.keys.each do |setting_key|
      cache_key = setting_cache_key(setting_key)
      stats[setting_key] = Rails.cache.exist?(cache_key)
    end

    stats
  end

  # キャッシュクリア（開発・テスト用）
  def self.clear_all_caches
    clear_cache

    SiteSetting::SETTING_TYPES.keys.each do |setting_key|
      clear_setting_cache(setting_key)
    end

    Rails.logger.info "SiteSetting caches cleared"
  end
end
