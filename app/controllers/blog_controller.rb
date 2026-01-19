class BlogController < ApplicationController
  def index
    # 検索パラメータの取得
    @query = params[:q].to_s.strip.presence

    # 記事の検索・フィルタリング
    page = params[:page].presence || 1
    cacheable = @query.blank? && params[:category_id].blank? && params[:tag_id].blank?

    if cacheable
      cached = Rails.cache.fetch("blog/page-#{page}", expires_in: 5.minutes) do
        relation = Article.published
                          .includes(:categories, :tags, thumbnail_image_attachment: :blob)
                          .order(published_at: :desc)
                          .page(page)
                          .per(10)
        { ids: relation.pluck(:id), total: relation.total_count }
      end

      articles = Article.published
                        .where(id: cached[:ids])
                        .includes(:categories, :tags, thumbnail_image_attachment: :blob)
                        .order(published_at: :desc)
      @articles = Kaminari.paginate_array(articles.to_a, total_count: cached[:total])
                           .page(page)
                           .per(10)
    else
      @articles = Article.published
                         .search(params[:q])
                         .by_category(params[:category_id])
                         .by_tag(params[:tag_id])
                         .includes(:categories, :tags, thumbnail_image_attachment: :blob)
                         .order(published_at: :desc)
                         .page(page)
                         .per(10)
    end

    # 選択中のカテゴリ・タグ
    @selected_category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
    @selected_tag = Tag.find_by(id: params[:tag_id]) if params[:tag_id].present?

    # カテゴリとタグ一覧（フィルタ用）
    category_ids = Rails.cache.fetch("sidebar/categories", expires_in: 10.minutes) do
      Category.with_published_articles.reorder(nil).pluck(:id)
    end
    tag_ids = Rails.cache.fetch("sidebar/tags", expires_in: 10.minutes) do
      Tag.with_published_articles.reorder(nil).pluck(:id)
    end

    @categories = Category.where(id: category_ids).order(:name)
    @tags = Tag.where(id: tag_ids).order(:name)

    # 検索時のSEOメタタグ設定
    set_meta_tags noindex: true if search_active?
  end

  def show
    # Eager load associations to prevent N+1 queries
    @article = Article.published
                      .includes(
                        :categories,
                        :tags,
                        thumbnail_image_attachment: :blob,
                        content_images_attachments: :blob
                      )
                      .find_by!(slug: params[:slug])

    # 関連記事（同じカテゴリの他の記事）- N+1問題を回避
    @related_articles = Article.published
                              .joins(:categories)
                              .where(categories: { id: @article.category_ids })
                              .where.not(id: @article.id)
                              .includes(:categories, thumbnail_image_attachment: :blob)
                              .order(published_at: :desc)
                              .limit(3)

    # パンくずリスト用（@articleで既にeager loadされているためN+1にならない）
    @categories = @article.categories.order(:position)
  end

  private

  def search_active?
    params[:q].present? || params[:category_id].present? || params[:tag_id].present?
  end
end
