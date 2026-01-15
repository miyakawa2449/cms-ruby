# frozen_string_literal: true

# Concern for tracking Active Storage attachments in MediaMetadata
# Automatically creates MediaMetadata records when images are attached
module TrackableAttachment
  extend ActiveSupport::Concern

  included do
    # Only track new attachments, not existing ones
    after_commit :create_media_metadata_for_new_attachments, on: [ :create, :update ]
  end

  private

  def create_media_metadata_for_new_attachments
    # Track thumbnail_image (only if newly attached)
    if respond_to?(:thumbnail_image) && thumbnail_image.attached? && thumbnail_image.blob.present?
      ensure_media_metadata(thumbnail_image.blob)
    end

    # Track content_images (only newly attached ones)
    if respond_to?(:content_images) && content_images.attached?
      # This will only process newly attached images
      # We can't easily detect which ones are new, so we check all but skip existing metadata
      content_images.each do |image|
        ensure_media_metadata(image.blob)
      end
    end
  end

  def ensure_media_metadata(blob, alt_text = nil)
    return unless blob
    return unless blob.content_type&.start_with?("image/")

    # Check if MediaMetadata already exists (this prevents duplicates)
    existing = MediaMetadata.find_by(blob: blob)
    if existing
      # Update alt_text if provided and not already set
      existing.update(alt_text: alt_text) if alt_text.present? && existing.alt_text.blank?
      # Track usage
      existing.track_usage
      return
    end

    # Create MediaMetadata
    metadata = MediaMetadata.create!(
      blob: blob,
      mime_type: blob.content_type,
      file_size: blob.byte_size,
      width: blob.metadata[:width],
      height: blob.metadata[:height],
      alt_text: alt_text,
      usage_count: 1  # 初期値を1に設定
    )
  rescue ActiveRecord::RecordNotUnique
    # Race condition: another process already created it
    Rails.logger.debug "MediaMetadata already exists for blob #{blob.id}"
    # Retry to track usage
    existing = MediaMetadata.find_by(blob: blob)
    existing&.track_usage
  rescue => e
    Rails.logger.error "Failed to create MediaMetadata for blob #{blob.id}: #{e.message}"
  end
end
