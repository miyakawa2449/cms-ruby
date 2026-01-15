class Api::V1::CategoriesController < Api::V1::BaseController
  before_action :set_category, only: [ :show, :articles ]

  # GET /api/v1/categories
  def index
    if params[:flat] == "true"
      # フラット表示の場合は記事があるカテゴリのみ
      @categories = Category.includes(:parent)
                           .where.not(article_count: 0)
                           .order(:position, :name)
      render_success(@categories.map { |category| CategorySerializer.new(category).serializable_hash })
    else
      # ツリー表示の場合は記事がある子カテゴリを持つ親カテゴリも含める
      categories_with_articles = Category.where.not(article_count: 0)
      parent_ids = categories_with_articles.where.not(parent_id: nil).pluck(:parent_id).uniq

      @categories = Category.includes(:parent)
                           .where("article_count > 0 OR id IN (?)", parent_ids.presence || [ 0 ])
                           .order(:position, :name)

      render_success(build_category_tree)
    end
  end

  # GET /api/v1/categories/:id
  def show
    render_success(CategorySerializer.new(@category, detailed: true).serializable_hash)
  end

  # GET /api/v1/categories/:id/articles
  def articles
    @articles = @category.articles.published
                        .includes(:categories, :tags)
                        .page(params[:page] || 1)
                        .per(params[:per_page] || 10)
                        .recent

    serialized_data = @articles.map { |article| ArticleSerializer.new(article).serializable_hash }

    meta = {
      pagination: {
        current_page: @articles.current_page,
        total_pages: @articles.total_pages,
        total_count: @articles.total_count,
        per_page: @articles.limit_value
      }
    }

    render_success(serialized_data, meta: meta)
  end

  private

  def set_category
    @category = Category.find(params[:id])

    # 記事が存在しないカテゴリは404
    raise ActiveRecord::RecordNotFound if @category.article_count == 0
  end

  def build_category_tree
    # 親カテゴリのみを取得
    parent_categories = @categories.where(parent_id: nil)

    parent_categories.map do |parent|
      category_data = CategorySerializer.new(parent).serializable_hash

      # 子カテゴリを追加
      children = @categories.where(parent_id: parent.id)
      if children.any?
        category_data[:children] = children.map { |child| CategorySerializer.new(child).serializable_hash }
      end

      category_data
    end
  end
end
