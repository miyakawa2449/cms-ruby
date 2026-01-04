# frozen_string_literal: true

module Admin
  # Media library management controller
  # Handles image uploads, listing, editing, and deletion
  class MediaController < BaseController
    before_action :set_media, only: [:show, :update, :destroy, :edit_image, :usage]

    # GET /admin/media
    def index
      @media = filtered_media.page(params[:page]).per(params[:per_page] || 50)
      @view_mode = params[:view] || 'grid'

      respond_to do |format|
        format.html
        format.json { render json: media_json_response }
      end
    end

    # GET /admin/media/:id
    def show
      respond_to do |format|
        format.html
        format.json { render json: { success: true, data: media_data(@media) } }
      end
    end

    # POST /admin/media
    def create
      result = Media::UploadService.new(
        upload_params[:images],
        generate_webp: upload_params[:generate_webp] == 'true',
        generate_thumbnails: upload_params[:generate_thumbnails] == 'true'
      ).call

      respond_to do |format|
        format.html do
          if result[:uploaded].any?
            flash[:notice] = "#{result[:uploaded].count}件の画像をアップロードしました"
          end
          if result[:failed].any?
            flash[:alert] = "#{result[:failed].count}件の画像のアップロードに失敗しました"
          end
          redirect_to admin_media_path
        end
        format.json { render json: { success: true, data: result } }
      end
    end

    # PATCH/PUT /admin/media/:id
    def update
      if @media.update(media_params)
        respond_to do |format|
          format.html do
            flash[:notice] = '画像情報を更新しました'
            redirect_to admin_media_path
          end
          format.json { render json: { success: true, data: media_data(@media) } }
        end
      else
        respond_to do |format|
          format.html do
            flash[:alert] = '画像情報の更新に失敗しました'
            redirect_to admin_media_path
          end
          format.json { render json: { success: false, errors: @media.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /admin/media/:id
    def destroy
      if @media.used?
        respond_to do |format|
          format.html do
            flash[:alert] = "この画像は#{@media.usage_count}件の記事で使用中です。削除できません。"
            redirect_to admin_media_path
          end
          format.json { render json: { success: false, error: '使用中の画像は削除できません' }, status: :unprocessable_entity }
        end
        return
      end

      blob = @media.blob
      @media.destroy
      blob.purge_later if blob

      respond_to do |format|
        format.html do
          flash[:notice] = '画像を削除しました'
          redirect_to admin_media_path
        end
        format.json { render json: { success: true } }
      end
    end

    # POST /admin/media/:id/edit_image
    def edit_image
      save_edited_image
    end

    # GET /admin/media/:id/usage
    def usage
      articles = find_articles_using_media(@media)

      respond_to do |format|
        format.json do
          render json: {
            success: true,
            data: {
              usage_count: @media.usage_count,
              articles: articles.map { |a| article_summary(a) }
            }
          }
        end
      end
    end

    private

    def save_edited_image
      save_as_new = params[:save_as_new] == 'true'
      uploaded_file = params[:image]

      unless uploaded_file
        render json: { success: false, error: 'No image provided' }, status: :unprocessable_entity
        return
      end

      if save_as_new
        create_new_media(uploaded_file)
      else
        update_existing_media(uploaded_file)
      end
    rescue => e
      Rails.logger.error "Edit image error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    def create_new_media(uploaded_file)
      new_blob = ActiveStorage::Blob.create_and_upload!(
        io: uploaded_file,
        filename: generate_edited_filename(@media.filename),
        content_type: uploaded_file.content_type || 'image/jpeg'
      )

      new_metadata = MediaMetadata.create!(
        blob: new_blob,
        mime_type: new_blob.content_type,
        file_size: new_blob.byte_size,
        alt_text: @media.alt_text
      )

      # Analyze for dimensions
      analyze_and_update_dimensions(new_blob, new_metadata)

      render json: {
        success: true,
        data: {
          id: new_metadata.id,
          filename: new_blob.filename.to_s,
          message: '新しい画像として保存しました'
        }
      }
    end

    def update_existing_media(uploaded_file)
      old_blob = @media.blob

      new_blob = ActiveStorage::Blob.create_and_upload!(
        io: uploaded_file,
        filename: @media.filename,
        content_type: uploaded_file.content_type || @media.mime_type
      )

      @media.update!(
        blob: new_blob,
        mime_type: new_blob.content_type,
        file_size: new_blob.byte_size
      )

      # Analyze for dimensions
      analyze_and_update_dimensions(new_blob, @media)

      # Delete old blob
      old_blob.purge_later if old_blob

      render json: {
        success: true,
        data: {
          id: @media.id,
          filename: new_blob.filename.to_s,
          message: '画像を上書き保存しました'
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

    def set_media
      @media = MediaMetadata.find(params[:id])
    end

    def media_params
      params.require(:media_metadata).permit(:alt_text)
    end

    def upload_params
      params.permit(:generate_webp, :generate_thumbnails, images: [])
    end

    def filtered_media
      media = MediaMetadata.includes(:blob).recent

      # Search by filename
      media = media.search(params[:q]) if params[:q].present?

      # Filter by usage
      case params.dig(:filter, :usage)
      when 'used'
        media = media.used
      when 'unused'
        media = media.unused
      end

      # Filter by mime type
      media = media.by_mime_type(params.dig(:filter, :mime_type)) if params.dig(:filter, :mime_type).present?

      # Filter by date range
      if params.dig(:filter, :date_from).present? && params.dig(:filter, :date_to).present?
        media = media.created_between(
          Date.parse(params.dig(:filter, :date_from)).beginning_of_day,
          Date.parse(params.dig(:filter, :date_to)).end_of_day
        )
      end

      # Sort
      case params[:sort]
      when 'size_asc'
        media = media.by_size(:asc)
      when 'size_desc'
        media = media.by_size(:desc)
      when 'name_asc'
        media = media.joins(:blob).order('active_storage_blobs.filename ASC')
      when 'name_desc'
        media = media.joins(:blob).order('active_storage_blobs.filename DESC')
      else
        media = media.recent
      end

      media
    end

    def media_json_response
      {
        success: true,
        data: {
          media: @media.map { |m| media_data(m) },
          meta: {
            current_page: @media.current_page,
            total_pages: @media.total_pages,
            total_count: @media.total_count,
            per_page: @media.limit_value
          }
        }
      }
    end

    def media_data(media)
      {
        id: media.id,
        filename: media.filename,
        url: media.url,
        thumbnail_url: media.variant_url(:thumb),
        alt_text: media.alt_text,
        width: media.width,
        height: media.height,
        file_size: media.file_size,
        human_file_size: media.human_file_size,
        mime_type: media.mime_type,
        usage_count: media.usage_count,
        created_at: media.created_at.iso8601,
        dimensions: media.dimensions
      }
    end

    def find_articles_using_media(media)
      # Find articles that reference this media's blob
      Article.published.select do |article|
        article.content.to_s.include?(media.blob.key)
      end
    end

    def article_summary(article)
      {
        id: article.id,
        title: article.title,
        published_at: article.published_at,
        url: "/blog/#{article.slug}"
      }
    end
  end
end
