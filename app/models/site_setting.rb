# サイト全体設定（6項目）。設定定義・値の取得/更新はこのモデルに集約し、
# キャッシュのみ SiteSettingCacheManager が担当する（S1-7 P2-3で3Managerを統合）
class SiteSetting < ApplicationRecord
  # 設定種別の定義
  SETTING_TYPES = {
    favicon: { key: "favicon", type: "image", description: "サイトのFavicon画像（16x16px, 32x32px推奨）" },
    logo: { key: "logo", type: "image", description: "サイトのロゴ画像（ヘッダー・フッター用、横長推奨）" },
    og_image: { key: "og_image", type: "image", description: "デフォルトOG画像（1200x630px推奨）" },
    site_title: { key: "site_title", type: "text", description: "サイトのタイトル", default: "Miyakawa Codes - ポートフォリオ" },
    site_description: { key: "site_description", type: "text", description: "サイトの説明文", default: "要件定義からプログラミングまで一人でできるエンジニアのポートフォリオサイト" },
    gtm_id: { key: "gtm_id", type: "text", description: "Google Tag Manager ID（例: GTM-XXXXXXX）", default: "", optional: true }
  }.freeze

  VALID_TYPES = %w[text image file].freeze

  validates :key, presence: true, uniqueness: true
  validates :setting_type, inclusion: { in: VALID_TYPES }

  has_one_attached :image_value
  has_one_attached :file_value

  # 各設定を返すクラスメソッド（SiteSetting.site_title 等。キャッシュ経由）
  SETTING_TYPES.each_key do |setting_name|
    define_singleton_method(setting_name) do
      SiteSettingCacheManager.fetch_all_settings[setting_name]
    end
  end

  # Callbacks
  after_save :clear_settings_cache
  after_destroy :clear_settings_cache

  def self.default_for(setting_name)
    SETTING_TYPES.dig(setting_name.to_sym, :default)
  end

  def self.clear_cache
    SiteSettingCacheManager.clear_cache
  end

  # 値を取得（画像/ファイルはAttachment、テキストは文字列）
  def get_value
    case setting_type
    when "image"
      image_value
    when "file"
      file_value
    else
      read_attribute(:value)
    end
  end

  # バリデーション付きの値更新。{ valid:, errors:/setting: } を返す
  def update_value(new_value)
    errors_found = validate_new_value(new_value)
    return { valid: false, errors: errors_found } if errors_found.any?

    case setting_type
    when "image"
      self.image_value = new_value
    when "file"
      self.file_value = new_value
    else
      self.value = new_value
    end
    save!

    { valid: true, setting: self }
  end

  private

  def validate_new_value(new_value)
    config = SETTING_TYPES[read_attribute(:key)&.to_sym]
    return [ "Setting not found" ] unless config

    errors_found = []
    case config[:type]
    when "text"
      # optional指定のある設定（gtm_id等）は空に戻すことを許可する
      errors_found << "Value cannot be blank" if new_value.blank? && !config[:optional]
      errors_found << "Value too long (max 1000 chars)" if new_value.to_s.length > 1000
    when "image", "file"
      # ファイルの検証は別途Active Storageで行う
    end
    errors_found
  end

  def clear_settings_cache
    SiteSettingCacheManager.clear_cache
  end
end
