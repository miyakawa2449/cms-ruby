# frozen_string_literal: true

module Media
  # Service for uploading media files
  # Handles validation, blob creation, and metadata extraction
  class UploadService
    MAX_FILE_SIZE = 10.megabytes
    ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

    def initialize(files, options = {})
      @files = Array(files)
      @generate_webp = options[:generate_webp]
      @generate_thumbnails = options[:generate_thumbnails]
    end

    def call
      results = { uploaded: [], failed: [] }

      @files.each do |file|
        if valid_file?(file)
          upload_file(file, results)
        else
          results[:failed] << format_error(file)
        end
      end

      results
    end

    private

    def valid_file?(file)
      valid_content_type?(file) && valid_file_size?(file)
    end

    def valid_content_type?(file)
      ALLOWED_CONTENT_TYPES.include?(file.content_type)
    end

    def valid_file_size?(file)
      file.size <= MAX_FILE_SIZE
    end

    def upload_file(file, results)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      metadata = create_metadata(blob)

      # Analyze blob for dimensions
      blob.analyze unless blob.analyzed?

      # Update metadata with dimensions
      if blob.metadata[:width] && blob.metadata[:height]
        metadata.update(
          width: blob.metadata[:width],
          height: blob.metadata[:height]
        )
      end

      results[:uploaded] << format_success(blob, metadata)
    rescue => e
      Rails.logger.error "Upload error: #{e.message}"
      results[:failed] << { filename: file.original_filename, error: e.message }
    end

    def create_metadata(blob)
      MediaMetadata.create!(
        blob: blob,
        mime_type: blob.content_type,
        file_size: blob.byte_size
      )
    end

    def format_success(blob, metadata)
      {
        id: metadata.id,
        filename: blob.filename.to_s,
        url: Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true),
        status: 'success'
      }
    end

    def format_error(file)
      error_message = if !valid_content_type?(file)
                        'Invalid file type'
                      elsif !valid_file_size?(file)
                        'File size exceeds limit (10MB)'
                      else
                        'Unknown error'
                      end

      {
        filename: file.original_filename,
        error: error_message
      }
    end
  end
end
