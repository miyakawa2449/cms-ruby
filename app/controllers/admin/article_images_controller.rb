class Admin::ArticleImagesController < Admin::BaseController
  # POST /admin/articles/:article_id/images
  def create
    @article = Article.find(params[:article_id])

    if params[:image].present?
      # Active Storageに画像を添付
      @article.content_images.attach(params[:image])

      # 最後に添付された画像を取得
      image = @article.content_images.last

      if image.present?
        # MediaMetadataにalt_textを保存
        metadata = MediaMetadata.find_or_create_by(blob: image.blob) do |m|
          m.mime_type = image.blob.content_type
          m.file_size = image.blob.byte_size
          m.width = image.blob.metadata[:width]
          m.height = image.blob.metadata[:height]
        end
        
        # alt_textを更新
        alt_text = params[:alt_text].presence || image.filename.to_s
        metadata.update(alt_text: alt_text) if alt_text.present?
        
        # 使用状況を追跡
        metadata.track_usage

        # 画像URLを生成
        image_url = url_for(image)
        caption = params[:caption].presence

        # キャプションの有無で生成するコードを分岐
        markdown = generate_image_code(image_url, alt_text, caption)

        render json: {
          success: true,
          markdown: markdown,
          url: image_url,
          alt_text: alt_text,
          caption: caption,
          filename: image.filename.to_s
        }
      else
        render json: { success: false, error: '画像のアップロードに失敗しました' }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: '画像ファイルが選択されていません' }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Article image upload error: #{e.message}"
    render json: { success: false, error: "エラーが発生しました: #{e.message}" }, status: :internal_server_error
  end

  private

  # キャプションの有無で画像コードを生成
  def generate_image_code(image_url, alt_text, caption)
    if caption
      # XSS対策: HTMLエスケープ
      escaped_alt = ERB::Util.html_escape(alt_text)
      escaped_caption = ERB::Util.html_escape(caption)

      <<~HTML.strip
        <figure class="article-image">
          <img src="#{image_url}" alt="#{escaped_alt}" />
          <figcaption>#{escaped_caption}</figcaption>
        </figure>
      HTML
    else
      # キャプションなしの場合は従来通りMarkdown形式
      "![#{alt_text}](#{image_url})"
    end
  end
end
