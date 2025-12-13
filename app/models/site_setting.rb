class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :setting_type, inclusion: { in: %w[text image file] }
  
  has_one_attached :image_value
  has_one_attached :file_value

  # 設定種別の定数
  SETTING_TYPES = {
    favicon: { key: 'favicon', type: 'image', description: 'サイトのFavicon画像（16x16px, 32x32px推奨）' },
    logo: { key: 'logo', type: 'image', description: 'サイトのロゴ画像（ヘッダー・フッター用、横長推奨）' },
    og_image: { key: 'og_image', type: 'image', description: 'デフォルトOG画像（1200x630px推奨）' },
    site_title: { key: 'site_title', type: 'text', description: 'サイトのタイトル', default: 'Miyakawa Codes - ポートフォリオ' },
    site_description: { key: 'site_description', type: 'text', description: 'サイトの説明文', default: '要件定義からプログラミングまで一人でできるエンジニアのポートフォリオサイト' }
  }.freeze
  
  # 動的にクラスメソッドを生成
  SETTING_TYPES.each do |setting_name, config|
    define_singleton_method(setting_name) do
      find_or_create_by(key: config[:key]) do |setting|
        setting.description = config[:description]
        setting.setting_type = config[:type]
        setting.value = config[:default] if config[:default]
      end
    end
  end
  
  # 値を取得（画像の場合はAttachmentオブジェクト、テキストの場合は文字列）
  def get_value
    case setting_type
    when 'image'
      image_value
    when 'file'
      file_value
    else
      value
    end
  end

  # 画像が添付されているかチェック
  def image_attached?
    setting_type == 'image' && image_value.attached?
  end

  # ファイルが添付されているかチェック
  def file_attached?
    setting_type == 'file' && file_value.attached?
  end

  # 設定値が存在するかチェック
  def has_value?
    case setting_type
    when 'image'
      image_attached?
    when 'file'
      file_attached?
    else
      value.present?
    end
  end

  # 設定の種別一覧を取得
  def self.available_types
    SETTING_TYPES.keys
  end

  # すべての設定を一括取得（キャッシュ対応）
  def self.all_settings
    Rails.cache.fetch('site_settings_all', expires_in: 1.hour) do
      SETTING_TYPES.keys.each_with_object({}) do |setting_name, settings|
        settings[setting_name] = public_send(setting_name)
      end
    end
  end

  # キャッシュのクリア
  def self.clear_cache
    Rails.cache.delete('site_settings_all')
  end

  # レコード更新後にキャッシュをクリア
  after_save :clear_settings_cache
  after_destroy :clear_settings_cache

  private

  def clear_settings_cache
    self.class.clear_cache
  end
end
