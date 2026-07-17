# frozen_string_literal: true

# メディアライブラリのJSONレスポンス整形（S1-7 P2-2でコントローラから分離）
class MediaMetadataSerializer
  def initialize(media)
    @media = media
  end

  def serializable_hash
    {
      id: @media.id,
      filename: @media.filename,
      url: @media.url,
      thumbnail_url: @media.variant_url(:thumb),
      alt_text: @media.alt_text,
      width: @media.width,
      height: @media.height,
      file_size: @media.file_size,
      human_file_size: @media.human_file_size,
      mime_type: @media.mime_type,
      usage_count: @media.usage_count,
      created_at: @media.created_at.iso8601,
      dimensions: @media.dimensions
    }
  end

  def self.collection(media_list)
    media_list.map { |media| new(media).serializable_hash }
  end
end
