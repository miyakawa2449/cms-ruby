class Api::V1::ArticlesController < Api::V1::BaseController
  before_action :set_article, only: [:show]
  
  # GET /api/v1/articles
  def index
    @articles = Article.published
                      .includes(:categories, :tags)
                      .page(params[:page] || 1)
                      .per(params[:per_page] || 10)
    
    # フィルタリング
    @articles = @articles.by_category(params[:category_id]) if params[:category_id].present?
    @articles = @articles.by_tag(params[:tag_id]) if params[:tag_id].present?
    @articles = @articles.search_by_content(params[:search]) if params[:search].present?
    
    # ソート
    @articles = case params[:sort]
                when 'title'
                  @articles.order(:title)
                when 'created_at'
                  @articles.order(:created_at)
                else
                  @articles.recent
                end
    
    serialized_data = @articles.map { |article| ArticleSerializer.new(article).serializable_hash }
    
    meta = {
      pagination: {
        current_page: @articles.current_page,
        total_pages: @articles.total_pages,
        total_count: @articles.total_count,
        per_page: @articles.limit_value
      }
    }
    
    render_success(serialized_data, meta: meta)
  end
  
  # GET /api/v1/articles/:id
  # GET /api/v1/articles/:slug
  def show
    render_success(ArticleSerializer.new(@article, detailed: true).serializable_hash)
  end
  
  private
  
  def set_article
    slug_param = params[:slug] || params[:id]
    
    @article = if slug_param.to_i.to_s == slug_param
                 Article.published.find(slug_param)
               else
                 Article.published.find_by!(slug: slug_param)
               end
  end
end