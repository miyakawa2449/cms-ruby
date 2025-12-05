class PortfolioController < ApplicationController
  def index
    # セクションデータを取得
    @sections = Section.includes(:active_content).visible.ordered
    
    # ブログの最新記事を取得（ブログセクション用）
    @recent_articles = Article.published.includes(:categories, :tags).recent.limit(3)
  end
end