# frozen_string_literal: true

module Media
  # Service for uploading media files
  # Handles validation, blob creation, and metadata extraction
  class UploadService
    # 検証定数はMediaValidatableに一元化（S1-7 P1-4）

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
      MediaValidatable::ALLOWED_IMAGE_TYPES.include?(file.content_type)
    end

    def valid_file_size?(file)
      file.size <= MediaValidatable::MAX_FILE_SIZE
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
      blob.reload

      width, height = extract_dimensions(blob)
      metadata.update(width: width, height: height) if width && height

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

    def extract_dimensions(blob)
      width = blob.metadata[:width]
      height = blob.metadata[:height]
      return [ width, height ] if width && height

      data = blob.download

      if data.start_with?("\xFF\xD8".b)
        read_jpeg_dimensions(data)
      elsif data.start_with?("\x89PNG\r\n\x1A\n".b)
        width, height = data.byteslice(16, 8).unpack("N2")
        [ width, height ]
      elsif data.start_with?("GIF87a") || data.start_with?("GIF89a")
        width, height = data.byteslice(6, 4).unpack("v2")
        [ width, height ]
      else
        [ nil, nil ]
      end
    rescue => e
      Rails.logger.warn "Failed to extract image dimensions: #{e.message}"
      [ nil, nil ]
    end

    def read_jpeg_dimensions(data)
      i = 2
      while i < data.bytesize
        i += 1 while i < data.bytesize && data.getbyte(i) != 0xFF
        break if i >= data.bytesize
        i += 1 while i < data.bytesize && data.getbyte(i) == 0xFF
        break if i >= data.bytesize
        marker = data.getbyte(i)
        i += 1
        next if marker == 0xD8 || marker == 0xD9
        break if i + 2 > data.bytesize
        length = data.byteslice(i, 2).unpack1("n")
        i += 2
        break if length < 2
        sof_markers = [
          0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
          0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF
        ]
        if sof_markers.include?(marker)
          height = data.byteslice(i + 1, 2).unpack1("n")
          width = data.byteslice(i + 3, 2).unpack1("n")
          return [ width, height ]
        end
        i += length - 2
      end

      [ nil, nil ]
    end

    def format_success(blob, metadata)
      {
        id: metadata.id,
        filename: blob.filename.to_s,
        url: Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true),
        status: "success"
      }
    end

    def format_error(file)
      error_message = if !valid_content_type?(file)
                        "Invalid file type"
      elsif !valid_file_size?(file)
                        "File size exceeds limit (#{MediaValidatable::MAX_FILE_SIZE / 1.megabyte}MB)"
      else
                        "Unknown error"
      end

      {
        filename: file.original_filename,
        error: error_message
      }
    end
  end
end
