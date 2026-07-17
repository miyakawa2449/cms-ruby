# frozen_string_literal: true

module Media
  # メディアライブラリの編集済み画像の保存（S1-7 P2-2でコントローラから分離）
  # save_as_new: true で別ファイルとして保存、falseで既存メディアを上書きする
  class ImageEditService
    def initialize(media, uploaded_file, save_as_new: false)
      @media = media
      @uploaded_file = uploaded_file
      @save_as_new = save_as_new
    end

    def call
      return { success: false, error: "No image provided" } unless @uploaded_file

      if @save_as_new
        create_new_media
      else
        update_existing_media
      end
    rescue => e
      Rails.logger.error "Edit image error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: e.message }
    end

    private

    def create_new_media
      new_blob = ActiveStorage::Blob.create_and_upload!(
        io: @uploaded_file,
        filename: generate_edited_filename(@media.filename),
        content_type: @uploaded_file.content_type || "image/jpeg"
      )

      new_metadata = MediaMetadata.create!(
        blob: new_blob,
        mime_type: new_blob.content_type,
        file_size: new_blob.byte_size,
        alt_text: @media.alt_text
      )

      analyze_and_update_dimensions(new_blob, new_metadata)

      {
        success: true,
        data: {
          id: new_metadata.id,
          filename: new_blob.filename.to_s,
          message: "新しい画像として保存しました"
        }
      }
    end

    def update_existing_media
      old_blob = @media.blob

      new_blob = ActiveStorage::Blob.create_and_upload!(
        io: @uploaded_file,
        filename: @media.filename,
        content_type: @uploaded_file.content_type || @media.mime_type
      )

      @media.update!(
        blob: new_blob,
        mime_type: new_blob.content_type,
        file_size: new_blob.byte_size
      )

      analyze_and_update_dimensions(new_blob, @media)

      # Delete old blob
      old_blob.purge_later if old_blob

      {
        success: true,
        data: {
          id: @media.id,
          filename: new_blob.filename.to_s,
          message: "画像を上書き保存しました"
        }
      }
    end

    def analyze_and_update_dimensions(blob, metadata)
      blob.analyze unless blob.analyzed?

      if blob.metadata[:width] && blob.metadata[:height]
        metadata.update(
          width: blob.metadata[:width],
          height: blob.metadata[:height]
        )
      end
    end

    def generate_edited_filename(original)
      extension = File.extname(original)
      basename = File.basename(original, extension)
      "#{basename}_edited_#{Time.current.to_i}#{extension}"
    end
  end
end
