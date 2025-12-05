class BlogController < ApplicationController
  def index
    @articles = Article.published
                      .includes(:categories, :tags)
                      .recent
                      .limit(10)
    
    # カテゴリとタグ一覧（サイドバー用）
    @categories = Category.with_published_articles.ordered
    @tags = Tag.with_published_articles.ordered_by_count
    
    # 検索処理
    if params[:search].present?
      @articles = @articles.search_by_content(params[:search])
    end
    
    if params[:category].present?
      @articles = @articles.joins(:categories).where(categories: { slug: params[:category] })
    end
    
    if params[:tag].present?
      @articles = @articles.joins(:tags).where(tags: { slug: params[:tag] })
    end
  end

  def show
    @article = Article.published.find_by!(slug: params[:slug])
    
    # 関連記事（同じカテゴリの他の記事）
    @related_articles = Article.published
                              .joins(:categories)
                              .where(categories: { id: @article.category_ids })
                              .where.not(id: @article.id)
                              .recent
                              .limit(3)
    
    # パンくずリスト用
    @categories = @article.categories.ordered
  end
end