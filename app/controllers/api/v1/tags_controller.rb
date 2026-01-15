class Api::V1::TagsController < Api::V1::BaseController
  before_action :set_tag, only: [ :show, :articles ]

  # GET /api/v1/tags
  def index
    @tags = Tag.where.not(article_count: 0) # 記事があるタグのみ
               .order(:name)
               .page(params[:page] || 1)
               .per(params[:per_page] || 50)

    # 検索機能
    if params[:search].present?
      @tags = @tags.where("name ILIKE ?", "%#{params[:search]}%")
    end

    render_paginated(@tags, TagSerializer)
  end

  # GET /api/v1/tags/:id
  def show
    render_success(TagSerializer.new(@tag, detailed: true).serializable_hash)
  end

  # GET /api/v1/tags/:id/articles
  def articles
    @articles = @tag.articles.published
                   .includes(:categories, :tags)
                   .page(params[:page] || 1)
                   .per(params[:per_page] || 10)
                   .recent

    render_paginated(@articles, ArticleSerializer)
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])

    # 記事が存在しないタグは404
    raise ActiveRecord::RecordNotFound if @tag.article_count == 0
  end
end
