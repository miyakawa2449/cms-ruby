# frozen_string_literal: true

module JsonStorable
  extend ActiveSupport::Concern

  included do
    # JSON stored データのデフォルト値設定
    before_validation :ensure_json_data_defaults
  end

  class_methods do
    # JSONフィールド用のヘルパーメソッド定義
    def json_field_accessors(field_name, *keys)
      keys.each do |key|
        define_method "#{key}" do
          read_json_field(field_name, key.to_s)
        end

        define_method "#{key}=" do |value|
          write_json_field(field_name, key.to_s, value)
        end
      end
    end
  end

  # JSON データ安全読み込み
  def read_json_field(field_name, key)
    return nil unless respond_to?(field_name)

    begin
      data = send(field_name) || {}
      data = JSON.parse(data) if data.is_a?(String)
      data[key]
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error for #{self.class.name}##{field_name}: #{e.message}"
      nil
    end
  end

  # JSON データ安全書き込み
  def write_json_field(field_name, key, value)
    return unless respond_to?("#{field_name}=")

    begin
      current_data = send(field_name) || {}
      current_data = JSON.parse(current_data) if current_data.is_a?(String)
      current_data = {} unless current_data.is_a?(Hash)

      if value.nil?
        current_data.delete(key)
      else
        current_data[key] = value
      end

      send("#{field_name}=", current_data)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error for #{self.class.name}##{field_name}: #{e.message}"
      send("#{field_name}=", { key => value })
    end
  end

  # JSON データ全体更新
  def update_json_field(field_name, new_data)
    return false unless respond_to?("#{field_name}=")
    return false unless new_data.is_a?(Hash)

    begin
      send("#{field_name}=", new_data)
      true
    rescue => e
      Rails.logger.error "JSON field update error for #{self.class.name}##{field_name}: #{e.message}"
      false
    end
  end

  # JSON データマージ
  def merge_json_field(field_name, merge_data)
    return false unless respond_to?(field_name) && merge_data.is_a?(Hash)

    begin
      current_data = send(field_name) || {}
      current_data = JSON.parse(current_data) if current_data.is_a?(String)
      current_data = {} unless current_data.is_a?(Hash)

      merged_data = current_data.deep_merge(merge_data)
      send("#{field_name}=", merged_data)
      true
    rescue JSON::ParserError, NoMethodError => e
      Rails.logger.error "JSON field merge error for #{self.class.name}##{field_name}: #{e.message}"
      false
    end
  end

  # JSON データクリア
  def clear_json_field(field_name)
    return false unless respond_to?("#{field_name}=")

    send("#{field_name}=", {})
    true
  end

  # JSON データ存在チェック
  def json_field_present?(field_name, key = nil)
    data = send(field_name) rescue nil
    return false if data.blank?

    begin
      parsed_data = data.is_a?(String) ? JSON.parse(data) : data
      return parsed_data.present? if key.nil?

      parsed_data.is_a?(Hash) && parsed_data[key].present?
    rescue JSON::ParserError
      false
    end
  end

  # JSON データのキー一覧取得
  def json_field_keys(field_name)
    begin
      data = send(field_name) || {}
      data = JSON.parse(data) if data.is_a?(String)
      data.is_a?(Hash) ? data.keys : []
    rescue JSON::ParserError, NoMethodError
      []
    end
  end

  private

  # JSON フィールドのデフォルト値を保証
  def ensure_json_data_defaults
    json_fields = self.class.columns.select { |col| col.type == :json || col.sql_type_metadata&.type == :jsonb }

    json_fields.each do |field|
      field_name = field.name
      next unless respond_to?(field_name) && respond_to?("#{field_name}=")

      current_value = send(field_name)
      if current_value.nil?
        send("#{field_name}=", {})
      elsif current_value.is_a?(String) && current_value.blank?
        send("#{field_name}=", {})
      end
    end
  end
end
