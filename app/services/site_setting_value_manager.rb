class SiteSettingValueManager
  def initialize(site_setting)
    @setting = site_setting
  end

  # 値を取得（画像の場合はAttachmentオブジェクト、テキストの場合は文字列）
  def get_value
    case @setting.setting_type
    when 'image'
      @setting.image_value
    when 'file'
      @setting.file_value
    else
      @setting.read_attribute(:value)
    end
  end

  # 値を設定
  def set_value(new_value)
    case @setting.setting_type
    when 'image'
      @setting.image_value = new_value
    when 'file'
      @setting.file_value = new_value
    else
      @setting.value = new_value
    end
    
    save_setting
  end

  # 安全な値の更新（バリデーション付き）
  def update_value(new_value)
    validation = validate_value(new_value)
    return validation unless validation[:valid]

    set_value(new_value)
    { valid: true, setting: @setting }
  end

  # 値の存在チェック
  def has_value?
    case @setting.setting_type
    when 'image'
      image_attached?
    when 'file'
      file_attached?
    else
      @setting.read_attribute(:value).present?
    end
  end

  # 画像が添付されているかチェック
  def image_attached?
    @setting.setting_type == 'image' && @setting.image_value.attached?
  end

  # ファイルが添付されているかチェック
  def file_attached?
    @setting.setting_type == 'file' && @setting.file_value.attached?
  end

  # デフォルト値の復元
  def restore_default
    setting_key = @setting.read_attribute(:key)
    type_config = SiteSettingTypeManager.setting_config(setting_key)
    return false unless type_config&.dig(:default)

    default_value = type_config[:default]
    set_value(default_value)
  end

  # 値のフォーマット（表示用）
  def formatted_value
    value = get_value
    
    case @setting.setting_type
    when 'image', 'file'
      if value&.attached?
        {
          filename: value.filename.to_s,
          size: value.byte_size,
          content_type: value.content_type,
          url: url_for_attachment(value)
        }
      else
        nil
      end
    else
      value.to_s
    end
  end

  # 画像URL生成（安全）
  def image_url(variant_options = {})
    return nil unless image_attached?
    
    begin
      if variant_options.any?
        url_for_attachment(@setting.image_value.variant(variant_options))
      else
        url_for_attachment(@setting.image_value)
      end
    rescue => e
      Rails.logger.error "Failed to generate image URL: #{e.message}"
      nil
    end
  end

  # ファイルダウンロードURL生成
  def download_url
    return nil unless file_attached?
    
    begin
      url_for_attachment(@setting.file_value)
    rescue => e
      Rails.logger.error "Failed to generate download URL: #{e.message}"
      nil
    end
  end

  # 値のバックアップ
  def backup_value
    {
      key: @setting.read_attribute(:key),
      type: @setting.read_attribute(:setting_type),
      value: case @setting.read_attribute(:setting_type)
             when 'image', 'file'
               # ファイルのバックアップは別途考慮
               has_value? ? 'attached_file' : nil
             else
               get_value
             end,
      backed_up_at: Time.current
    }
  end

  private

  def save_setting
    @setting.save!
  end

  def validate_value(value)
    SiteSettingTypeManager.validate_setting_config(
      @setting.read_attribute(:key),
      value,
      @setting.read_attribute(:setting_type)
    )
  end

  def url_for_attachment(attachment)
    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
  end
end