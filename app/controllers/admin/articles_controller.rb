class Admin::ArticlesController < Admin::BaseController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :publish, :unpublish]
  
  def index
    # フィルタリングをサービスに委譲
    filter_service = ArticleFilterService.new
    @articles = filter_service.filter(params)
    
    # 統計情報をサービスに委譲
    stats = ArticleStatisticsService.new.index_stats
    @total_count = stats[:total_count]
    @published_count = stats[:published_count]
    @draft_count = stats[:draft_count]
    
    # フィルタ用データ
    @categories = Category.ordered
  end
  
  def show
  end
  
  def new
    @article = current_admin_user.articles.build
    setup_form_data
  end
  
  def edit
    setup_form_data
  end
  
  def create
    @article = current_admin_user.articles.build(article_params)
    
    if @article.save
      redirect_to admin_article_path(@article), notice: "記事を作成しました。"
    else
      setup_form_data
      render :new, status: :unprocessable_entity
    end
  end
  
  def update
    if @article.update(article_params)
      redirect_to admin_article_path(@article), notice: "記事を更新しました。"
    else
      setup_form_data
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @article.destroy
    redirect_to admin_articles_path, notice: "記事を削除しました。"
  end
  
  def publish
    publishing_service = ArticlePublishingService.new(@article)
    result = publishing_service.publish
    
    if result[:success]
      redirect_to admin_articles_path, notice: result[:message]
    else
      redirect_to admin_articles_path, alert: result[:message]
    end
  end
  
  def unpublish
    publishing_service = ArticlePublishingService.new(@article)
    result = publishing_service.unpublish
    
    if result[:success]
      redirect_to admin_articles_path, notice: result[:message]
    else
      redirect_to admin_articles_path, alert: result[:message]
    end
  end
  
  private
  
  def set_article
    # IDが数値の場合はIDで検索、そうでなければslugで検索
    if params[:id] =~ /\A\d+\z/
      @article = Article.find(params[:id])
    else
      @article = Article.find_by!(slug: params[:id])
    end
  end

  def setup_form_data
    association_service = ArticleAssociationService.new(@article)
    form_data = association_service.setup_for_form
    @categories = form_data[:categories]
  end
  
  def article_params
    params.require(:article).permit(
      :title, :slug, :content, :excerpt, :status,
      :meta_description, :meta_keywords, :og_title, :og_description,
      :tag_names, :thumbnail_image, :work_type, :github_url, :demo_url, :tech_stack,
      category_ids: []
    )
  end
end