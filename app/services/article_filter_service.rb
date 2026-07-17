# frozen_string_literal: true

# 管理画面の記事一覧のフィルタリング・検索を担当するサービス
# 各軸の絞り込みはArticleのスコープに委譲する（S1-7 P1-1で重複SQLを統合）
class ArticleFilterService
  attr_reader :articles

  def initialize(articles = Article.all)
    @articles = articles
  end

  def filter(params)
    # Eager load associations to prevent N+1 queries
    result = @articles.includes(
      :admin_user,
      :categories,
      ogp_image_attachment: :blob
    )
                     .order(created_at: :desc)

    result = filter_by_status(result, params[:status])
    result = result.by_category(params[:category_id])
    result = result.by_tag(params[:tag_id])
    result = result.search_by_content(params[:search])
    result = result.where(work_type: params[:work_type]) if params[:work_type].present?

    result.page(params[:page])
  end

  private

  def filter_by_status(articles, status)
    return articles unless status.present?

    case status
    when "published"
      articles.published
    when "draft"
      articles.draft
    else
      articles.where(status: status)
    end
  end
end
