class Admin::ArticlesController < Admin::BaseController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :publish, :unpublish]
  
  def index
    @articles = Article.includes(:admin_user, :categories, :tags)
                      .order(created_at: :desc)
                      .page(params[:page])
    
    # フィルタリング
    @articles = @articles.where(status: params[:status]) if params[:status].present?
    @articles = @articles.joins(:categories).where(categories: { id: params[:category_id] }) if params[:category_id].present?
    
    # 統計情報
    @total_count = Article.count
    @published_count = Article.published.count
    @draft_count = Article.draft.count
    
    # フィルタ用データ
    @categories = Category.ordered
  end
  
  def show
  end
  
  def new
    @article = current_admin_user.articles.build
    @categories = Category.ordered
    @article.categories.build if @article.categories.empty?
  end
  
  def edit
    @categories = Category.ordered
  end
  
  def create
    @article = current_admin_user.articles.build(article_params)
    
    if @article.save
      redirect_to admin_article_path(@article), notice: "記事を作成しました。"
    else
      @categories = Category.ordered
      render :new, status: :unprocessable_entity
    end
  end
  
  def update
    if @article.update(article_params)
      redirect_to admin_article_path(@article), notice: "記事を更新しました。"
    else
      @categories = Category.ordered
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @article.destroy
    redirect_to admin_articles_path, notice: "記事を削除しました。"
  end
  
  def publish
    if @article.update(status: 'published', published_at: Time.current)
      redirect_to admin_articles_path, notice: "記事を公開しました。"
    else
      redirect_to admin_articles_path, alert: "公開に失敗しました。"
    end
  end
  
  def unpublish
    if @article.update(status: 'draft', published_at: nil)
      redirect_to admin_articles_path, notice: "記事を非公開にしました。"
    else
      redirect_to admin_articles_path, alert: "非公開化に失敗しました。"
    end
  end
  
  private
  
  def set_article
    @article = Article.find(params[:id])
  end
  
  def article_params
    params.require(:article).permit(
      :title, :slug, :content, :excerpt, :status,
      :meta_description, :meta_keywords, :og_title, :og_description,
      :tag_names, category_ids: []
    )
  end
end