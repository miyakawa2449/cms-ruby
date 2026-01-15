# frozen_string_literal: true

# 記事のフィルタリング・検索機能を担当するサービス
class ArticleFilterService
  attr_reader :articles

  def initialize(articles = Article.all)
    @articles = articles
  end

  def filter(params)
    result = @articles.includes(:admin_user, :categories, :tags)
                     .order(created_at: :desc)

    result = filter_by_status(result, params[:status])
    result = filter_by_category(result, params[:category_id])
    result = filter_by_tag(result, params[:tag_id])
    result = filter_by_search(result, params[:search])
    result = filter_by_work_type(result, params[:work_type])

    paginate_results(result, params[:page])
  end

  private

  def filter_by_status(articles, status)
    return articles unless status.present?

    case status
    when "published"
      articles.published
    when "draft"
      articles.draft
    when "scheduled"
      articles.where(status: "scheduled")
    else
      articles.where(status: status)
    end
  end

  def filter_by_category(articles, category_id)
    return articles unless category_id.present?

    articles.joins(:categories).where(categories: { id: category_id })
  end

  def filter_by_tag(articles, tag_id)
    return articles unless tag_id.present?

    articles.joins(:tags).where(tags: { id: tag_id })
  end

  def filter_by_search(articles, search_term)
    return articles unless search_term.present?

    articles.where(
      "title ILIKE ? OR content ILIKE ? OR excerpt ILIKE ?",
      "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"
    )
  end

  def filter_by_work_type(articles, work_type)
    return articles unless work_type.present?

    articles.where(work_type: work_type)
  end

  def paginate_results(articles, page)
    if defined?(Kaminari)
      articles.page(page)
    else
      articles
    end
  end
end
