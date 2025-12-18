class SiteSettingTypeManager
  # 設定種別の定数（SiteSettingから移動）
  SETTING_TYPES = {
    favicon: { key: 'favicon', type: 'image', description: 'サイトのFavicon画像（16x16px, 32x32px推奨）' },
    logo: { key: 'logo', type: 'image', description: 'サイトのロゴ画像（ヘッダー・フッター用、横長推奨）' },
    og_image: { key: 'og_image', type: 'image', description: 'デフォルトOG画像（1200x630px推奨）' },
    site_title: { key: 'site_title', type: 'text', description: 'サイトのタイトル', default: 'Miyakawa Codes - ポートフォリオ' },
    site_description: { key: 'site_description', type: 'text', description: 'サイトの説明文', default: '要件定義からプログラミングまで一人でできるエンジニアのポートフォリオサイト' },
    gtm_id: { key: 'gtm_id', type: 'text', description: 'Google Tag Manager ID（例: GTM-XXXXXXX）', default: '' }
  }.freeze

  VALID_TYPES = %w[text image file].freeze

  def self.available_settings
    SETTING_TYPES.keys
  end

  def self.setting_config(setting_name)
    SETTING_TYPES[setting_name.to_sym]
  end

  def self.setting_type(setting_name)
    config = setting_config(setting_name)
    config&.dig(:type)
  end

  def self.setting_description(setting_name)
    config = setting_config(setting_name)
    config&.dig(:description)
  end

  def self.setting_default(setting_name)
    config = setting_config(setting_name)
    config&.dig(:default)
  end

  def self.valid_type?(type)
    VALID_TYPES.include?(type.to_s)
  end

  # 設定の種別ごとにグループ化
  def self.settings_by_type
    SETTING_TYPES.group_by { |_, config| config[:type] }
  end

  # 画像系設定の一覧
  def self.image_settings
    SETTING_TYPES.select { |_, config| config[:type] == 'image' }.keys
  end

  # テキスト系設定の一覧
  def self.text_settings
    SETTING_TYPES.select { |_, config| config[:type] == 'text' }.keys
  end

  # ファイル系設定の一覧
  def self.file_settings
    SETTING_TYPES.select { |_, config| config[:type] == 'file' }.keys
  end

  # 設定の検証
  def self.validate_setting_config(setting_name, value, type)
    config = setting_config(setting_name)
    return { valid: false, errors: ['Setting not found'] } unless config

    errors = []
    
    # タイプ検証
    unless config[:type] == type
      errors << "Expected type '#{config[:type]}', got '#{type}'"
    end

    # 値の検証
    case config[:type]
    when 'text'
      errors << 'Value cannot be blank' if value.blank?
      errors << 'Value too long (max 1000 chars)' if value.to_s.length > 1000
    when 'image', 'file'
      # ファイルの検証は別途Active Storageで行う
    end

    { valid: errors.empty?, errors: errors }
  end

  # 設定の初期化データ
  def self.initial_settings_data
    SETTING_TYPES.map do |setting_name, config|
      {
        key: config[:key],
        setting_type: config[:type],
        description: config[:description],
        value: config[:default]
      }.compact
    end
  end

  # 動的メソッド生成のためのヘルパー
  def self.define_setting_methods_on(klass)
    SETTING_TYPES.each do |setting_name, config|
      klass.define_singleton_method(setting_name) do
        find_or_create_by(key: config[:key]) do |setting|
          setting.description = config[:description]
          setting.setting_type = config[:type]
          setting.value = config[:default] if config[:default]
        end
      end
    end
  end

  # 管理画面用の設定情報
  def self.admin_setting_options
    SETTING_TYPES.map do |setting_name, config|
      {
        name: setting_name,
        key: config[:key],
        type: config[:type],
        description: config[:description],
        default: config[:default],
        required: config[:required] || false
      }
    end
  end
end