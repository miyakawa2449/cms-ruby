# Generates image variants (thumbnails) for uploaded media
class Media::GenerateVariantsJob < ApplicationJob
  queue_as :default

  def perform(media_metadata_id)
    metadata = MediaMetadata.find_by(id: media_metadata_id)
    return unless metadata

    metadata.generate_variants
  rescue => e
    Rails.logger.error "GenerateVariantsJob error for MediaMetadata##{media_metadata_id}: #{e.message}"
    raise e # Re-raise to trigger retry
  end
end
