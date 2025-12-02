class BlogController < ApplicationController
  # GET /blog
  def index
    # ブログトップページ
    # @articles = Article.published.order(created_at: :desc).limit(10)
    # @categories = Category.with_article_count
  end

  # GET /blog/category/:slug
  def category
    @slug = params[:slug]
    
    # カテゴリ情報を設定（実際にはデータベースから取得）
    @category = case @slug
    when 'ai-ml'
      {
        name: 'AI・機械学習',
        icon: '🤖',
        description: 'ChatGPT、機械学習、自動化ツールの開発',
        article_count: 18
      }
    when 'ruby-rails'
      {
        name: 'Ruby/Rails',
        icon: '⚙️',
        description: 'Ruby on Railsを使ったWeb開発',
        article_count: 24
      }
    when 'requirements'
      {
        name: '要件定義・設計',
        icon: '🏗️',
        description: '上流工程とプロジェクト管理',
        article_count: 15
      }
    when 'infrastructure'
      {
        name: 'インフラ・デプロイ',
        icon: '🚀',
        description: 'AWS、Docker、CI/CDの実践',
        article_count: 12
      }
    else
      {
        name: 'カテゴリ',
        icon: '📂',
        description: '技術記事',
        article_count: 0
      }
    end
    
    # @articles = Article.where(category: @slug).published.order(created_at: :desc)
  end

  # GET /blog/article/:slug
  def article
    @slug = params[:slug]
    # @article = Article.find_by!(slug: @slug)
    # @related_articles = @article.related_articles.limit(2)
  end
end
