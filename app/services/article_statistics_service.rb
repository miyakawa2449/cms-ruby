# frozen_string_literal: true

# 記事の統計情報を管理するサービス
class ArticleStatisticsService
  def index_stats
    counts = Article.group(:status).count
    {
      total_count: counts.values.sum,
      published_count: counts["published"].to_i,
      draft_count: counts["draft"].to_i
    }
  end
end
