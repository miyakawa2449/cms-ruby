class Admin::ArticleImagesController < Admin::BaseController
  # Content image settings (800x600px, 4:3 aspect ratio)
  CONTENT_IMAGE_WIDTH = 800
  CONTENT_IMAGE_HEIGHT = 600
  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  # POST /admin/articles/:article_id/images
  def create
    @article = Article.find(params[:article_id])

    # Validate required parameters
    unless params[:image].present?
      return render_error('画像ファイルが選択されていません')
    end

    unless params[:alt_text].present?
      return render_error('alt属性は必須です')
    end

    # Validate file format (server-side)
    unless valid_image_format?(params[:image])
      return render_error('対応していないファイル形式です。JPEG, PNG, GIF, WebPを選択してください。')
    end

    # Validate file size (server-side)
    if params[:image].size > MAX_FILE_SIZE
      return render_error('ファイルサイズは10MB以下にしてください。')
    end

    # Attach image to Active Storage
    @article.content_images.attach(params[:image])
    image = @article.content_images.last

    if image.present?
      # Create or update MediaMetadata
      metadata = create_media_metadata(image, params[:alt_text])

      # Generate image URL
      image_url = url_for(image)
      caption = params[:caption].presence

      # Generate Markdown/HTML code
      markdown = generate_image_code(image_url, params[:alt_text], caption)

      render json: {
        success: true,
        markdown: markdown,
        url: image_url,
        alt_text: params[:alt_text],
        caption: caption,
        filename: image.filename.to_s,
        width: CONTENT_IMAGE_WIDTH,
        height: CONTENT_IMAGE_HEIGHT
      }
    else
      render_error('画像のアップロードに失敗しました')
    end
  rescue ActiveRecord::RecordNotFound
    render_error('記事が見つかりません', :not_found)
  rescue => e
    Rails.logger.error "Article image upload error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render_error("エラーが発生しました: #{e.message}")
  end

  private

  # Validate file format
  def valid_image_format?(file)
    ALLOWED_CONTENT_TYPES.include?(file.content_type)
  end

  # Create or update MediaMetadata
  def create_media_metadata(image, alt_text)
    MediaMetadata.find_or_create_by(blob: image.blob) do |m|
      m.mime_type = image.blob.content_type
      m.file_size = image.blob.byte_size
      m.width = CONTENT_IMAGE_WIDTH
      m.height = CONTENT_IMAGE_HEIGHT
    end.tap do |metadata|
      # Update alt_text and track usage
      metadata.update(alt_text: alt_text)
      metadata.track_usage
    end
  end

  # Generate image code based on caption presence
  def generate_image_code(image_url, alt_text, caption)
    if caption
      # XSS protection: HTML escape
      escaped_alt = ERB::Util.html_escape(alt_text)
      escaped_caption = ERB::Util.html_escape(caption)

      <<~HTML.strip
        <figure class="article-image">
          <img src="#{image_url}" alt="#{escaped_alt}" />
          <figcaption>#{escaped_caption}</figcaption>
        </figure>
      HTML
    else
      # Without caption: Markdown format
      "![#{alt_text}](#{image_url})"
    end
  end

  # Render error response
  def render_error(message, status = :unprocessable_entity)
    render json: { success: false, error: message }, status: status
  end
end
