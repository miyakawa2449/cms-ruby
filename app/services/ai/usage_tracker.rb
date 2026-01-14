# Tracks AI API usage and costs
# Aggregates statistics for monitoring and billing
module Ai
  class UsageTracker
    class << self
      # Track a single API usage
      # @param model_id [String] Model that was used
      # @param generation_type [Symbol] Type of generation
      # @param tokens [Integer] Total tokens used
      # @param cost [Float] Calculated cost
      def track(model_id:, generation_type:, tokens:, cost:)
        stat = AiUsageStat.for_today(model_id)
        stat.record_usage!(
          requests: 1,
          tokens: tokens,
          cost: cost,
          generation_type: generation_type.to_s
        )
      rescue => e
        Rails.logger.error("Failed to track AI usage: #{e.message}")
        # Don't raise - usage tracking shouldn't break the main flow
      end

      # Get usage summary for a date range
      # @param start_date [Date] Start date
      # @param end_date [Date] End date (defaults to today)
      # @return [Hash] Usage summary
      def summary(start_date:, end_date: Date.current)
        stats = AiUsageStat.where(date: start_date..end_date)

        {
          period: {
            start_date: start_date,
            end_date: end_date
          },
          totals: {
            requests: stats.sum(:total_requests),
            tokens: stats.sum(:total_tokens),
            cost: stats.sum(:total_cost).to_f.round(2)
          },
          by_model: model_breakdown(stats),
          by_date: daily_breakdown(stats),
          by_type: type_breakdown(start_date, end_date)
        }
      end

      # Get today's usage
      def today
        stats = AiUsageStat.for_date(Date.current)
        {
          date: Date.current,
          requests: stats.sum(:total_requests),
          tokens: stats.sum(:total_tokens),
          cost: stats.sum(:total_cost).to_f.round(2)
        }
      end

      # Get this month's usage
      def this_month
        start_date = Date.current.beginning_of_month
        summary(start_date: start_date)
      end

      # Check if monthly limit is exceeded
      def monthly_limit_exceeded?(limit_amount)
        this_month[:totals][:cost] >= limit_amount
      end

      # Get remaining budget for the month
      def remaining_budget(monthly_limit)
        used = this_month[:totals][:cost]
        [monthly_limit - used, 0].max.round(2)
      end

      private

      def model_breakdown(stats)
        stats.group(:ai_model).pluck(
          :ai_model,
          Arel.sql('SUM(total_requests)'),
          Arel.sql('SUM(total_tokens)'),
          Arel.sql('SUM(total_cost)')
        ).map do |model, requests, tokens, cost|
          {
            model: model,
            display_name: ModelSelector.display_name(model),
            requests: requests.to_i,
            tokens: tokens.to_i,
            cost: cost.to_f.round(2)
          }
        end
      end

      def daily_breakdown(stats)
        stats.group(:date).pluck(
          :date,
          Arel.sql('SUM(total_requests)'),
          Arel.sql('SUM(total_tokens)'),
          Arel.sql('SUM(total_cost)')
        ).sort_by(&:first).reverse.map do |date, requests, tokens, cost|
          {
            date: date,
            requests: requests.to_i,
            tokens: tokens.to_i,
            cost: cost.to_f.round(2)
          }
        end
      end

      def type_breakdown(start_date, end_date)
        generations = AiGeneration.where(created_at: start_date..end_date.end_of_day)
                                  .where(status: 'completed')

        AiGeneration::GENERATION_TYPES.map do |type|
          type_records = generations.where(generation_type: type)
          {
            type: type,
            requests: type_records.count,
            tokens: type_records.sum(:tokens_used),
            cost: type_records.sum(:cost).to_f.round(4)
          }
        end
      end
    end
  end
end
