# frozen_string_literal: true

# Validation for uploaded media blobs
module MediaValidatable
  extend ActiveSupport::Concern

  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  MAX_FILE_SIZE = 10.megabytes

  included do
    validate :validate_blob_content_type
    validate :validate_blob_file_size
  end

  private

  def validate_blob_content_type
    return if blob.blank?

    unless ALLOWED_IMAGE_TYPES.include?(blob.content_type)
      errors.add(:blob, "は JPEG、PNG、GIF、WebP 形式のみアップロード可能です")
      return
    end

    begin
      actual_type = Marcel::MimeType.for(blob.download)
      if actual_type && blob.content_type != actual_type
        errors.add(:blob, "のファイル形式が不正です")
      end
    rescue => e
      Rails.logger.error "File type validation error: #{e.message}"
      errors.add(:blob, "の検証中にエラーが発生しました")
    end
  end

  def validate_blob_file_size
    return if blob.blank?

    if blob.byte_size > MAX_FILE_SIZE
      errors.add(:blob, "のサイズは #{MAX_FILE_SIZE / 1.megabyte}MB 以下にしてください")
    end
  end
end
