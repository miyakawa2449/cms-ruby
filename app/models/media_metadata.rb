# frozen_string_literal: true

# MediaMetadata model for managing uploaded images
# Stores metadata and usage tracking for Active Storage blobs
class MediaMetadata < ApplicationRecord
  belongs_to :blob, class_name: "ActiveStorage::Blob"

  validates :blob, presence: true

  # Scopes
  scope :used, -> { where("usage_count > 0") }
  scope :unused, -> { where(usage_count: 0) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_size, ->(direction = :desc) { order(file_size: direction) }
  scope :by_mime_type, ->(type) { where(mime_type: type) }
  scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :search, ->(query) {
    joins(:blob).where("active_storage_blobs.filename LIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  # Track usage
  def track_usage
    increment!(:usage_count)
  end

  def untrack_usage
    return if usage_count <= 0

    decrement!(:usage_count)
  end

  def used?
    usage_count > 0
  end

  # Blob delegations
  def filename
    blob.filename.to_s
  end

  def url
    Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true)
  end

  def variant_url(variant_name)
    return nil unless variants[variant_name.to_s]

    variants[variant_name.to_s]
  end

  # Human readable file size
  def human_file_size
    return "0 B" if file_size.nil? || file_size.zero?

    units = [ "B", "KB", "MB", "GB" ]
    size = file_size.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024.0
      unit_index += 1
    end

    format("%.2f %s", size, units[unit_index])
  end

  # Image dimensions as string
  def dimensions
    return "不明" if width.nil? || height.nil?

    "#{width}x#{height}"
  end
end
