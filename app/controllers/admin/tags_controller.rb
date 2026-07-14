class Admin::TagsController < Admin::BaseController
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]

  def index
    @tags = Tag.includes(:articles).alphabetical
    @tags = @tags.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

    @total_count = Tag.count
    @popular_tags = Tag.popular.limit(10)
  end

  def show
    @articles = @tag.articles.includes(:admin_user, :categories).recent.limit(10)
    # Pre-calculate stats to prevent N+1 queries in view
    @oldest_article = @tag.articles.order(:created_at).first
    @newest_article = @tag.articles.order(created_at: :desc).first
  end

  def new
    @tag = Tag.new
  end

  def edit
  end

  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      redirect_to admin_tags_path, notice: "タグを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @tag.update(tag_params)
      redirect_to admin_tags_path, notice: "タグを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy
    redirect_to admin_tags_path, notice: "タグを削除しました。"
  end

  private

  def set_tag
    # Tag#to_param はslugを返すため、URLパラメータはslugで検索する
    @tag = Tag.find_by!(slug: params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :slug)
  end
end
