class BlogController < ApplicationController
  def index
    # 検索パラメータの取得
    @query = params[:q].to_s.strip.presence

    # 記事の検索・フィルタリング
    page = params[:page].presence || 1
    cacheable = @query.blank? && params[:category_id].blank? && params[:tag_id].blank?

    if cacheable
      cache_key = "blog/page-#{page}"
      cached = Rails.cache.read(cache_key)

      if cached
        articles = Article.published
                          .where(id: cached[:ids])
                          .includes(:categories, :tags, thumbnail_image_attachment: :blob, ogp_image_attachment: :blob)
                          .order(published_at: :desc)
                          .to_a
        preload_article_associations(articles)
        @articles = Kaminari.paginate_array(articles, total_count: cached[:total])
                             .page(page)
                             .per(10)
        @published_articles_count = cached[:total]
      else
        relation = Article.published
                          .includes(:categories, :tags, thumbnail_image_attachment: :blob, ogp_image_attachment: :blob)
                          .order(published_at: :desc)
                          .page(page)
                          .per(10)
        articles = relation.to_a
        preload_article_associations(articles)
        total = relation.total_count
        Rails.cache.write(cache_key, { ids: articles.map(&:id), total: total }, expires_in: 5.minutes)

        @articles = Kaminari.paginate_array(articles, total_count: total)
                             .page(page)
                             .per(10)
        @published_articles_count = total
      end
    else
      @articles = Article.published
                         .search(params[:q])
                         .by_category(params[:category_id])
                         .by_tag(params[:tag_id])
                         .includes(:categories, :tags, thumbnail_image_attachment: :blob, ogp_image_attachment: :blob)
                         .order(published_at: :desc)
                         .page(page)
                         .per(10)
    end

    # 選択中のカテゴリ・タグ
    @selected_category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
    @selected_tag = Tag.find_by(id: params[:tag_id]) if params[:tag_id].present?

    # カテゴリとタグ一覧（フィルタ用）
    @categories = Rails.cache.fetch("sidebar/categories", expires_in: 10.minutes) do
      Category.with_published_articles.order(:name).to_a
    end
    @tags = Rails.cache.fetch("sidebar/tags", expires_in: 10.minutes) do
      Tag.with_published_articles.order(:name).to_a
    end

    @published_articles_count ||= Rails.cache.fetch("articles/published_count", expires_in: 10.minutes) do
      Article.published.count
    end

    # 検索時のSEOメタタグ設定
    set_meta_tags noindex: true if search_active?
  end

  def show
    # Eager load associations to prevent N+1 queries
    @article = Article.published
                      .includes(
                        :categories,
                        :tags,
                        thumbnail_image_attachment: :blob, ogp_image_attachment: :blob
                      )
                      .find_by!(slug: params[:slug])

    # 関連記事（同じカテゴリの他の記事）- N+1問題を回避
    @related_articles = Article.published
                              .joins(:categories)
                              .where(categories: { id: @article.category_ids })
                              .where.not(id: @article.id)
                              .eager_load(:categories, thumbnail_image_attachment: :blob, ogp_image_attachment: :blob)
                              .order(published_at: :desc)
                              .limit(3)

    # パンくずリスト用（@articleで既にeager loadされているためN+1にならない）
    @categories = @article.categories.sort_by { |category| category.position.to_i }

    @about_section = Section.eager_load(active_content: { profile_image_attachment: :blob })
                            .find_by(name: "about")
  end

  private

  def search_active?
    params[:q].present? || params[:category_id].present? || params[:tag_id].present?
  end

  def preload_article_associations(articles)
    ActiveRecord::Associations::Preloader.new(
      records: articles,
      associations: [ :categories, :tags, { thumbnail_image_attachment: :blob, ogp_image_attachment: :blob } ]
    ).call
  end
end
