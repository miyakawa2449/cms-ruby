class BlogController < ApplicationController
  def index
    # 検索パラメータの取得
    @query = params[:q].to_s.strip.presence

    # 記事の検索・フィルタリング
    @articles = Article.published
                       .search(params[:q])
                       .by_category(params[:category_id])
                       .by_tag(params[:tag_id])
                       .includes(:categories, :tags, thumbnail_image_attachment: :blob)
                       .order(published_at: :desc)
                       .page(params[:page])
                       .per(10)

    # 選択中のカテゴリ・タグ
    @selected_category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
    @selected_tag = Tag.find_by(id: params[:tag_id]) if params[:tag_id].present?

    # カテゴリとタグ一覧（フィルタ用）
    @categories = Category.with_published_articles.order(:name)
    @tags = Tag.with_published_articles.order(:name)

    # 検索時のSEOメタタグ設定
    set_meta_tags noindex: true if search_active?
  end

  def show
    @article = Article.published.find_by!(slug: params[:slug])

    # 関連記事（同じカテゴリの他の記事）
    @related_articles = Article.published
                              .joins(:categories)
                              .where(categories: { id: @article.category_ids })
                              .where.not(id: @article.id)
                              .order(published_at: :desc)
                              .limit(3)

    # パンくずリスト用
    @categories = @article.categories.order(:position)
  end

  private

  def search_active?
    params[:q].present? || params[:category_id].present? || params[:tag_id].present?
  end
end
