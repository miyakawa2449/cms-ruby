# frozen_string_literal: true

# 記事の統計情報を管理するサービス
class ArticleStatisticsService
  def self.calculate
    new.calculate
  end

  def calculate
    {
      total_count: Article.count,
      published_count: Article.published.count,
      draft_count: Article.draft.count,
      scheduled_count: Article.where(status: 'scheduled').count,
      work_statistics: work_type_statistics,
      category_statistics: category_statistics,
      monthly_statistics: monthly_statistics
    }
  end

  def index_stats
    {
      total_count: Article.count,
      published_count: Article.published.count,
      draft_count: Article.draft.count
    }
  end

  private

  def work_type_statistics
    Article.group(:work_type).count
  end

  def category_statistics
    Category.joins(:articles)
            .group('categories.name')
            .count
  end

  def monthly_statistics
    Article.where('created_at >= ?', 12.months.ago)
           .group_by_month(:created_at)
           .count
  end
end