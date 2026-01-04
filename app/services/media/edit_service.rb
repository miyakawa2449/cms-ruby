# Handles media editing operations (crop, rotate, flip)
class Media::EditService
  VALID_OPERATIONS = %w[crop rotate flip].freeze

  def initialize(media_metadata, operation, params)
    @media = media_metadata
    @operation = operation.to_s
    @params = params.to_h.symbolize_keys
  end

  def call
    return { success: false, error: 'Invalid operation' } unless valid_operation?
    return { success: false, error: 'Media not found' } unless @media
    return { success: false, error: 'Not an image' } unless @media.image?

    case @operation
    when 'crop'
      crop_image
    when 'rotate'
      rotate_image
    when 'flip'
      flip_image
    end
  rescue => e
    Rails.logger.error "Media edit error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def valid_operation?
    VALID_OPERATIONS.include?(@operation)
  end

  def crop_image
    x = @params[:x].to_i
    y = @params[:y].to_i
    width = @params[:width].to_i
    height = @params[:height].to_i

    return { success: false, error: 'Invalid crop dimensions' } if width <= 0 || height <= 0

    # Generate cropped variant
    variant = @media.blob.variant(
      crop: "#{width}x#{height}+#{x}+#{y}"
    )

    if @params[:save_as_new]
      save_as_new_blob(variant)
    else
      # For now, we just return the variant URL
      # Full overwrite implementation would require more complex handling
      {
        success: true,
        data: {
          id: @media.id,
          variant_url: url_for_variant(variant)
        }
      }
    end
  end

  def rotate_image
    degrees = @params[:degrees].to_i
    return { success: false, error: 'Invalid rotation degrees' } unless [90, 180, 270, -90, -180, -270].include?(degrees)

    variant = @media.blob.variant(rotate: degrees)

    {
      success: true,
      data: {
        id: @media.id,
        variant_url: url_for_variant(variant)
      }
    }
  end

  def flip_image
    direction = @params[:direction].to_s

    transformations = case direction
    when 'horizontal'
      { flop: true }
    when 'vertical'
      { flip: true }
    else
      return { success: false, error: 'Invalid flip direction' }
    end

    variant = @media.blob.variant(transformations)

    {
      success: true,
      data: {
        id: @media.id,
        variant_url: url_for_variant(variant)
      }
    }
  end

  def save_as_new_blob(variant)
    # Process the variant to get the actual image data
    processed = variant.processed

    # Create a new blob from the processed variant
    new_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(processed.download),
      filename: generate_new_filename,
      content_type: @media.mime_type
    )

    # Create new metadata
    new_metadata = MediaMetadata.create!(
      blob: new_blob,
      mime_type: new_blob.content_type,
      file_size: new_blob.byte_size,
      alt_text: @media.alt_text
    )

    # Analyze and update dimensions
    new_blob.analyze
    new_metadata.update(
      width: new_blob.metadata[:width],
      height: new_blob.metadata[:height]
    )

    {
      success: true,
      data: {
        id: new_metadata.id,
        filename: new_blob.filename.to_s,
        url: url_for_blob(new_blob)
      }
    }
  end

  def generate_new_filename
    original = @media.filename.to_s
    extension = File.extname(original)
    basename = File.basename(original, extension)
    "#{basename}_edited_#{Time.current.to_i}#{extension}"
  end

  def url_for_variant(variant)
    Rails.application.routes.url_helpers.rails_representation_path(variant, only_path: true)
  end

  def url_for_blob(blob)
    Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
  end
end
