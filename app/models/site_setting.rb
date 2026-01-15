class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :setting_type, inclusion: { in: SiteSettingTypeManager::VALID_TYPES }

  has_one_attached :image_value
  has_one_attached :file_value

  # 設定種別の定数（TypeManagerから参照）
  SETTING_TYPES = SiteSettingTypeManager::SETTING_TYPES

  # 動的にクラスメソッドを生成
  SiteSettingTypeManager.define_setting_methods_on(self)

  # Service delegation methods
  def value_manager
    @value_manager ||= SiteSettingValueManager.new(self)
  end

  # Value management delegation
  delegate :get_value, :has_value?, :image_attached?, :file_attached?,
           :image_url, :download_url, :formatted_value,
           to: :value_manager

  # Type management delegation
  def self.available_types
    SiteSettingTypeManager.available_settings
  end

  def self.settings_by_type
    SiteSettingTypeManager.settings_by_type
  end

  def self.admin_setting_options
    SiteSettingTypeManager.admin_setting_options
  end

  # Cache management delegation
  def self.all_settings
    SiteSettingCacheManager.fetch_all_settings
  end

  def self.clear_cache
    SiteSettingCacheManager.clear_cache
  end

  def self.preload_common_settings
    SiteSettingCacheManager.preload_common_settings
  end

  # Callbacks
  after_save :clear_settings_cache
  after_destroy :clear_settings_cache

  private

  def clear_settings_cache
    SiteSettingCacheManager.clear_cache
  end
end
