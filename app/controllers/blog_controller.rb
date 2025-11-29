class BlogController < ApplicationController
  # 技術ブログのメインコントローラー
  # 記事一覧、詳細、カテゴリ別表示、検索機能を提供
  
  before_action :set_blog_data
  before_action :set_article, only: [:show]
  before_action :track_article_view, only: [:show]
  
  def index
    # ブログトップ（記事一覧）
    @page_title = '技術ブログ'
    @page_description = 'エンジニアとして学んだ技術や経験を記事として公開しています。'
    
    # Phase 2Bで実装予定
    # @articles = Article.published
    #                   .includes(:categories, :tags, :admin_user)
    #                   .order(published_at: :desc)
    #                   .page(params[:page])
    #                   .per(12)
    
    @articles = mock_articles_data
    @featured_article = @articles.first
    @recent_articles = @articles[1..5] || []
    
    # サイドバー用データ
    @popular_articles = @articles.sample(5)
    @categories = mock_categories_data
    @tags = mock_tags_data
  end
  
  def show
    # 記事詳細ページ
    @page_title = "#{@article[:title]} | 技術ブログ"
    @page_description = @article[:excerpt]
    @canonical_url = article_url(@article[:slug])
    
    # 関連記事（Phase 2Bで実装）
    # @related_articles = Article.published
    #                           .where.not(id: @article.id)
    #                           .joins(:article_categories)
    #                           .where(article_categories: { category_id: @article.category_ids })
    #                           .limit(4)
    
    @related_articles = @articles.sample(4)
    
    # コメント（Phase 2Bで実装）
    # @comments = @article.comments.approved.includes(:replies).roots
    # @new_comment = Comment.new
    
    @comments = []
  end
  
  def category
    # カテゴリ別記事一覧
    @category_slug = params[:slug]
    
    # Phase 2Bで実装予定
    # @category = Category.find_by(slug: @category_slug, visible: true)
    # render_not_found and return unless @category
    
    @category = mock_categories_data.find { |cat| cat[:slug] == @category_slug }
    render_not_found and return unless @category
    
    @page_title = "#{@category[:name]} | カテゴリ別記事"
    @page_description = @category[:description]
    
    # カテゴリの記事取得
    # @articles = @category.articles.published
    #                     .includes(:categories, :tags, :admin_user)
    #                     .order(published_at: :desc)
    #                     .page(params[:page])
    #                     .per(12)
    
    @articles = mock_articles_data.sample(8)
    
    # パンくずリスト用
    @breadcrumbs = build_category_breadcrumbs(@category)
  end
  
  def tag
    # タグ別記事一覧
    @tag_slug = params[:slug]
    
    # Phase 2Bで実装予定
    # @tag = Tag.find_by(slug: @tag_slug, visible: true)
    # render_not_found and return unless @tag
    
    @tag = mock_tags_data.find { |tag| tag[:slug] == @tag_slug }
    render_not_found and return unless @tag
    
    @page_title = "#{@tag[:name]} | タグ別記事"
    @page_description = "#{@tag[:name]}に関する記事一覧です。"
    
    # タグの記事取得
    # @articles = @tag.articles.published
    #                 .includes(:categories, :tags, :admin_user)
    #                 .order(published_at: :desc)
    #                 .page(params[:page])
    #                 .per(12)
    
    @articles = mock_articles_data.sample(6)
  end
  
  def search
    # 記事検索
    @query = params[:q].to_s.strip
    @page_title = @query.present? ? "「#{@query}」の検索結果" : '記事検索'
    @page_description = '記事をキーワードで検索できます。'
    
    if @query.present? && @query.length >= 2
      # Phase 2BでPostgreSQL全文検索を実装予定
      # @articles = Article.published
      #                   .where("search_vector @@ plainto_tsquery('japanese', ?)", @query)
      #                   .or(Article.where("title ILIKE ? OR excerpt ILIKE ?", "%#{@query}%", "%#{@query}%"))
      #                   .includes(:categories, :tags, :admin_user)
      #                   .order("ts_rank(search_vector, plainto_tsquery('japanese', ?)) DESC", @query)
      #                   .page(params[:page])
      #                   .per(12)
      
      @articles = mock_articles_data.select { |article| 
        article[:title].include?(@query) || article[:excerpt].include?(@query)
      }
      @search_count = @articles.length
    else
      @articles = []
      @search_count = 0
      @error_message = '検索キーワードは2文字以上で入力してください。' if @query.present?
    end
  end
  
  def archive
    # 年月別アーカイブ
    @year = params[:year].to_i
    @month = params[:month]&.to_i
    
    unless valid_archive_params?
      render_not_found and return
    end
    
    if @month
      @page_title = "#{@year}年#{@month}月の記事"
      @archive_period = Date.new(@year, @month)
    else
      @page_title = "#{@year}年の記事"
      @archive_period = Date.new(@year)
    end
    
    # Phase 2Bで実装予定
    # @articles = Article.published
    #                   .where(published_at: archive_date_range)
    #                   .includes(:categories, :tags, :admin_user)
    #                   .order(published_at: :desc)
    #                   .page(params[:page])
    #                   .per(12)
    
    @articles = mock_articles_data.sample(5)
  end
  
  def feed
    # RSS/Atom フィード
    @articles = mock_articles_data[0..20]
    
    respond_to do |format|
      format.atom { render layout: false }
      format.rss { redirect_to feed_path(format: :atom) }
    end
  end
  
  private
  
  def set_blog_data
    # ブログ共通データの設定
    @blog_title = 'Technical Blog'
    @blog_description = 'エンジニアリングに関する技術情報と学習記録'
    
    # サイドバー用の共通データ（Phase 2Bで実装）
    @recent_articles_sidebar = mock_articles_data[0..4]
    @popular_categories = mock_categories_data[0..5]
    @archive_months = mock_archive_data
  end
  
  def set_article
    # 記事詳細用のデータ取得
    @article_slug = params[:slug]
    
    # Phase 2Bで実装予定
    # @article = Article.published.find_by(slug: @article_slug)
    # render_not_found and return unless @article
    
    @article = mock_articles_data.find { |article| article[:slug] == @article_slug }
    render_not_found and return unless @article
  end
  
  def track_article_view
    # 記事ビューの追跡（Phase 2Bで実装）
    # ArticleViewJob.perform_async(@article.id, request_tracking_data)
    Rails.logger.info "Article view: #{@article[:slug]} from #{request.remote_ip}"
  end
  
  def valid_archive_params?
    return false unless @year.between?(2020, Date.current.year + 1)
    return true unless @month
    
    @month.between?(1, 12)
  end
  
  def archive_date_range
    if @month
      start_date = Date.new(@year, @month, 1)
      end_date = start_date.end_of_month
    else
      start_date = Date.new(@year, 1, 1)
      end_date = Date.new(@year, 12, 31)
    end
    
    start_date.beginning_of_day..end_date.end_of_day
  end
  
  def build_category_breadcrumbs(category)
    breadcrumbs = []
    
    # 親カテゴリがある場合（Phase 2Bで実装）
    # if category.parent
    #   breadcrumbs << { name: category.parent.name, path: category_path(category.parent.slug) }
    # end
    
    breadcrumbs << { name: category[:name], path: category_path(category[:slug]) }
    breadcrumbs
  end
  
  # Mock data for Phase 2A (Phase 2Bで実データに置き換え)
  def mock_articles_data
    [
      {
        id: 1,
        title: 'Rails 8.0の新機能解説',
        slug: 'rails-8-new-features',
        excerpt: 'Rails 8.0で追加された主要な新機能について詳しく解説します。',
        content: 'Rails 8.0の詳細な内容...',
        published_at: 2.days.ago,
        reading_time: 8,
        views_count: 156
      },
      {
        id: 2,
        title: 'PostgreSQL全文検索の実装方法',
        slug: 'postgresql-full-text-search',
        excerpt: 'PostgreSQLを使った日本語全文検索の実装について説明します。',
        content: 'PostgreSQL全文検索の詳細...',
        published_at: 1.week.ago,
        reading_time: 12,
        views_count: 234
      },
      {
        id: 3,
        title: 'Docker環境でのRails開発',
        slug: 'rails-development-with-docker',
        excerpt: 'Dockerを使ったRails開発環境の構築と運用のベストプラクティス。',
        content: 'Docker環境構築の詳細...',
        published_at: 2.weeks.ago,
        reading_time: 15,
        views_count: 189
      }
    ]
  end
  
  def mock_categories_data
    [
      { id: 1, name: 'Rails', slug: 'rails', description: 'Ruby on Railsに関する記事', articles_count: 15 },
      { id: 2, name: 'PostgreSQL', slug: 'postgresql', description: 'PostgreSQLデータベースに関する記事', articles_count: 8 },
      { id: 3, name: 'Docker', slug: 'docker', description: 'Dockerとコンテナ技術に関する記事', articles_count: 12 }
    ]
  end
  
  def mock_tags_data
    [
      { id: 1, name: 'Ruby', slug: 'ruby', articles_count: 25 },
      { id: 2, name: 'JavaScript', slug: 'javascript', articles_count: 18 },
      { id: 3, name: 'CSS', slug: 'css', articles_count: 10 }
    ]
  end
  
  def mock_archive_data
    [
      { year: 2024, month: 11, count: 3 },
      { year: 2024, month: 10, count: 5 },
      { year: 2024, month: 9, count: 4 }
    ]
  end
end