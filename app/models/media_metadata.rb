# frozen_string_literal: true

# MediaMetadata model for managing uploaded images
# Stores metadata and usage tracking for Active Storage blobs
class MediaMetadata < ApplicationRecord
  include MediaValidatable

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
  scope :by_filename, ->(direction = :asc) {
    joins(:blob).order("active_storage_blobs.filename #{direction == :desc ? 'DESC' : 'ASC'}")
  }

  # 管理画面一覧のフィルタ・並び替え（S1-7 P2-2でコントローラのif分岐からスコープ合成へ）
  def self.filtered(q: nil, usage: nil, mime_type: nil, date_from: nil, date_to: nil, sort: nil)
    media = includes(:blob).recent
    media = media.search(q) if q.present?

    case usage
    when "used" then media = media.used
    when "unused" then media = media.unused
    end

    media = media.by_mime_type(mime_type) if mime_type.present?

    if date_from.present? && date_to.present?
      media = media.created_between(
        Date.parse(date_from).beginning_of_day,
        Date.parse(date_to).end_of_day
      )
    end

    case sort
    when "size_asc" then media.by_size(:asc)
    when "size_desc" then media.by_size(:desc)
    when "name_asc" then media.by_filename(:asc)
    when "name_desc" then media.by_filename(:desc)
    else media.recent
    end
  end

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

  # この画像（blob key）を本文で参照している公開記事。
  # 旧実装は全公開記事をRubyで走査していた（S1-7 P2-2でSQL化）
  def articles_using
    Article.published.where(
      "content LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(blob.key)}%"
    )
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
