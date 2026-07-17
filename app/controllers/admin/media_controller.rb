# frozen_string_literal: true

module Admin
  # Media library management controller
  # 一覧フィルタはMediaMetadata.filtered、編集保存はMedia::ImageEditService、
  # JSON整形はMediaMetadataSerializerに委譲する（S1-7 P2-2で分割）
  class MediaController < BaseController
    before_action :set_media, only: [ :show, :update, :destroy, :edit_image, :usage ]

    # GET /admin/media
    def index
      @media = filtered_media.page(params[:page]).per(params[:per_page] || 50)
      @view_mode = params[:view] || "grid"

      respond_to do |format|
        format.html
        format.json { render json: media_json_response }
      end
    end

    # GET /admin/media/:id
    def show
      respond_to do |format|
        format.html
        format.json { render json: { success: true, data: MediaMetadataSerializer.new(@media).serializable_hash } }
      end
    end

    # POST /admin/media
    def create
      result = Media::UploadService.new(
        upload_params[:images],
        generate_webp: upload_params[:generate_webp] == "true",
        generate_thumbnails: upload_params[:generate_thumbnails] == "true"
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
            flash[:notice] = "画像情報を更新しました"
            redirect_to admin_media_path
          end
          format.json { render json: { success: true, data: MediaMetadataSerializer.new(@media).serializable_hash } }
        end
      else
        respond_to do |format|
          format.html do
            flash[:alert] = "画像情報の更新に失敗しました"
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
          format.json { render json: { success: false, error: "使用中の画像は削除できません" }, status: :unprocessable_entity }
        end
        return
      end

      blob = @media.blob
      @media.destroy
      blob.purge_later if blob

      respond_to do |format|
        format.html do
          flash[:notice] = "画像を削除しました"
          redirect_to admin_media_path
        end
        format.json { render json: { success: true } }
      end
    end

    # POST /admin/media/:id/edit_image
    def edit_image
      result = Media::ImageEditService.new(
        @media,
        params[:image],
        save_as_new: params[:save_as_new] == "true"
      ).call

      if result[:success]
        render json: result
      else
        render json: result, status: :unprocessable_entity
      end
    end

    # GET /admin/media/:id/usage
    def usage
      articles = @media.articles_using

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
      MediaMetadata.filtered(
        q: params[:q],
        usage: params.dig(:filter, :usage),
        mime_type: params.dig(:filter, :mime_type),
        date_from: params.dig(:filter, :date_from),
        date_to: params.dig(:filter, :date_to),
        sort: params[:sort]
      )
    end

    def media_json_response
      {
        success: true,
        data: {
          media: MediaMetadataSerializer.collection(@media),
          meta: {
            current_page: @media.current_page,
            total_pages: @media.total_pages,
            total_count: @media.total_count,
            per_page: @media.limit_value
          }
        }
      }
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
