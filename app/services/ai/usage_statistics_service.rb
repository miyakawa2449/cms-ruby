# Aggregates AI usage statistics for dashboard and reporting
# Provides methods for various time ranges and export functionality
module Ai
  class UsageStatisticsService
    # Get daily usage statistics for a date range
    # @param start_date [Date] Start date
    # @param end_date [Date] End date
    # @return [Array<Hash>] Daily statistics with date, requests, tokens, cost
    def self.daily_usage(start_date, end_date)
      AiUsageStat
        .where(date: start_date..end_date)
        .group(:date)
        .select(
          "date",
          "SUM(total_requests) as total_requests",
          "SUM(total_tokens) as total_tokens",
          "SUM(total_cost) as total_cost"
        )
        .order(:date)
        .map do |stat|
          {
            date: stat.date,
            requests: stat.total_requests.to_i,
            tokens: stat.total_tokens.to_i,
            cost: stat.total_cost.to_f.round(4)
          }
        end
    end

    # Get monthly usage statistics
    # @param year [Integer] Year
    # @param month [Integer] Month (1-12)
    # @return [Hash] Monthly summary with totals and daily breakdown
    def self.monthly_usage(year, month)
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      daily_stats = daily_usage(start_date, end_date)

      {
        year: year,
        month: month,
        total_requests: daily_stats.sum { |d| d[:requests] },
        total_tokens: daily_stats.sum { |d| d[:tokens] },
        total_cost: daily_stats.sum { |d| d[:cost] }.round(4),
        daily_breakdown: daily_stats,
        model_breakdown: model_breakdown(start_date, end_date)
      }
    end

    # Get usage breakdown by feature/generation type
    # @param start_date [Date] Start date
    # @param end_date [Date] End date
    # @return [Array<Hash>] Usage by feature type
    def self.usage_by_feature(start_date, end_date)
      AiGeneration
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        .completed
        .group(:generation_type)
        .select(
          "generation_type",
          "COUNT(*) as count",
          "SUM(input_tokens + output_tokens) as total_tokens",
          "SUM(cost) as total_cost"
        )
        .order("count DESC")
        .map do |gen|
          {
            feature: gen.generation_type,
            feature_label: feature_label(gen.generation_type),
            count: gen.count.to_i,
            tokens: gen.total_tokens.to_i,
            cost: gen.total_cost.to_f.round(4)
          }
        end
    end

    # Get total cost for a date range
    # @param start_date [Date] Start date
    # @param end_date [Date] End date
    # @return [Float] Total cost in USD
    def self.total_cost(start_date, end_date)
      AiUsageStat
        .where(date: start_date..end_date)
        .sum(:total_cost)
        .to_f
        .round(4)
    end

    # Get top features by usage count
    # @param limit [Integer] Number of features to return
    # @param start_date [Date] Optional start date (defaults to 30 days ago)
    # @param end_date [Date] Optional end date (defaults to today)
    # @return [Array<Hash>] Top features by usage
    def self.top_features(limit = 5, start_date: 30.days.ago.to_date, end_date: Date.current)
      usage_by_feature(start_date, end_date)
        .first(limit)
    end

    # Export usage data to CSV format
    # @param start_date [Date] Start date
    # @param end_date [Date] End date
    # @return [String] CSV formatted string
    def self.export_data(start_date, end_date)
      require "csv"

      generations = AiGeneration
        .includes(:article)
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        .order(created_at: :desc)

      CSV.generate(headers: true) do |csv|
        csv << [
          "日時",
          "機能",
          "記事ID",
          "記事タイトル",
          "モデル",
          "入力トークン",
          "出力トークン",
          "コスト(USD)",
          "ステータス"
        ]

        generations.each do |gen|
          csv << [
            gen.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            feature_label(gen.generation_type),
            gen.article_id,
            gen.article&.title || "-",
            gen.model_id || "-",
            gen.input_tokens,
            gen.output_tokens,
            gen.cost&.round(6) || 0,
            status_label(gen.status)
          ]
        end
      end
    end

    # Get summary statistics for dashboard
    # @return [Hash] Summary with today, this month, and trends
    def self.dashboard_summary
      today = Date.current
      this_month_start = today.beginning_of_month
      last_month_start = (today - 1.month).beginning_of_month
      last_month_end = last_month_start.end_of_month

      today_stats = daily_usage(today, today).first || { requests: 0, tokens: 0, cost: 0 }
      this_month_stats = monthly_usage(today.year, today.month)
      last_month_stats = monthly_usage(last_month_start.year, last_month_start.month)

      # Calculate trend (percentage change from last month)
      cost_trend = calculate_trend(this_month_stats[:total_cost], last_month_stats[:total_cost])
      requests_trend = calculate_trend(this_month_stats[:total_requests], last_month_stats[:total_requests])

      {
        today: today_stats,
        this_month: {
          requests: this_month_stats[:total_requests],
          tokens: this_month_stats[:total_tokens],
          cost: this_month_stats[:total_cost]
        },
        last_month: {
          requests: last_month_stats[:total_requests],
          tokens: last_month_stats[:total_tokens],
          cost: last_month_stats[:total_cost]
        },
        trends: {
          cost: cost_trend,
          requests: requests_trend
        },
        top_features: top_features(5),
        recent_generations: recent_generations(10)
      }
    end

    # Get model breakdown for a date range
    # @param start_date [Date] Start date
    # @param end_date [Date] End date
    # @return [Array<Hash>] Usage by model
    def self.model_breakdown(start_date, end_date)
      AiUsageStat
        .where(date: start_date..end_date)
        .group(:ai_model)
        .select(
          "ai_model",
          "SUM(total_requests) as total_requests",
          "SUM(total_tokens) as total_tokens",
          "SUM(total_cost) as total_cost"
        )
        .order("total_cost DESC")
        .map do |stat|
          {
            model: stat.ai_model,
            requests: stat.total_requests.to_i,
            tokens: stat.total_tokens.to_i,
            cost: stat.total_cost.to_f.round(4)
          }
        end
    end

    # Get chart data for daily usage visualization
    # @param days [Integer] Number of days to include
    # @return [Hash] Data formatted for Chart.js
    def self.chart_data(days: 30)
      start_date = days.days.ago.to_date
      end_date = Date.current
      daily_stats = daily_usage(start_date, end_date)

      # Fill in missing dates with zeros
      date_range = (start_date..end_date).to_a
      stats_by_date = daily_stats.index_by { |s| s[:date] }

      filled_stats = date_range.map do |date|
        stats_by_date[date] || { date: date, requests: 0, tokens: 0, cost: 0 }
      end

      {
        labels: filled_stats.map { |s| s[:date].strftime("%m/%d") },
        datasets: {
          requests: filled_stats.map { |s| s[:requests] },
          tokens: filled_stats.map { |s| s[:tokens] },
          cost: filled_stats.map { |s| s[:cost] }
        }
      }
    end

    private_class_method

    # Convert generation type to Japanese label
    def self.feature_label(generation_type)
      labels = {
        "summary" => "要約生成",
        "title" => "タイトル提案",
        "tags" => "タグ提案",
        "slug" => "スラッグ生成",
        "seo_meta" => "SEOメタ生成",
        "structure" => "構成提案"
      }
      labels[generation_type] || generation_type
    end

    # Convert status to Japanese label
    def self.status_label(status)
      labels = {
        "pending" => "処理中",
        "completed" => "完了",
        "failed" => "失敗"
      }
      labels[status] || status
    end

    # Calculate percentage trend
    def self.calculate_trend(current, previous)
      return 0 if previous.zero?
      ((current - previous) / previous.to_f * 100).round(1)
    end

    # Get recent generations for activity feed
    def self.recent_generations(limit = 10)
      AiGeneration
        .includes(:article)
        .order(created_at: :desc)
        .limit(limit)
        .map do |gen|
          {
            id: gen.id,
            feature: gen.generation_type,
            feature_label: feature_label(gen.generation_type),
            article_title: gen.article&.title,
            status: gen.status,
            status_label: status_label(gen.status),
            created_at: gen.created_at,
            cost: gen.cost&.round(4) || 0
          }
        end
    end
  end
end
