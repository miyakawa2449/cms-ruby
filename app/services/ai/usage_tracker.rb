# Tracks AI API usage and costs
# 記録専任（S1-7 P1-5）。集計・レポートは Ai::UsageStatisticsService を使うこと
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
    end
  end
end
