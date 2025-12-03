class Admin::DashboardController < Admin::BaseController
  def index
    @articles_count = Article.count
    @published_articles_count = Article.published.count
    @draft_articles_count = Article.draft.count
    @sections_count = Section.count
    @categories_count = Category.count
    @tags_count = Tag.count
    @recent_articles = Article.recent.includes(:admin_user, :categories).limit(5)
  end
end