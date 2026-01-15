class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: [ :show, :edit, :update, :destroy, :move_up, :move_down ]

  def index
    @root_categories = Category.root_categories.includes(:children).ordered
    @total_count = Category.count
    @root_count = Category.root_categories.count
  end

  def show
    @articles = @category.articles.includes(:admin_user).recent.limit(10)
  end

  def new
    @category = Category.new
    @parent_categories = Category.root_categories.ordered
  end

  def edit
    @parent_categories = Category.root_categories.where.not(id: @category.id).ordered
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_categories_path, notice: "カテゴリを作成しました。"
    else
      @parent_categories = Category.root_categories.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "カテゴリを更新しました。"
    else
      @parent_categories = Category.root_categories.where.not(id: @category.id).ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.articles.any?
      redirect_to admin_categories_path, alert: "記事が関連付けられているため削除できません。"
    else
      @category.destroy
      redirect_to admin_categories_path, notice: "カテゴリを削除しました。"
    end
  end

  def move_up
    @category.update(position: [ @category.position - 1, 0 ].max)
    redirect_to admin_categories_path
  end

  def move_down
    @category.update(position: @category.position + 1)
    redirect_to admin_categories_path
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :slug, :description, :icon, :color, :position, :parent_id)
  end
end
