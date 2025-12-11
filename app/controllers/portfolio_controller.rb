class PortfolioController < ApplicationController
  def index
    # セクションデータを取得
    @sections = Section.includes(:active_content).visible.ordered
    
    # ブログの最新記事を取得（Works記事除外）
    @recent_articles = Article.published
                              .includes(:categories, :tags)
                              .joins('LEFT JOIN article_categories ON articles.id = article_categories.article_id')
                              .joins('LEFT JOIN categories ON article_categories.category_id = categories.id')
                              .where('categories.slug IS NULL OR categories.slug != ?', 'works')
                              .recent
                              .limit(3)
  end
end