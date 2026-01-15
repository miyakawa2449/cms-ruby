# Daily AI usage statistics
# Aggregates API usage by date and model for cost tracking and monitoring
class AiUsageStat < ApplicationRecord
  # Validations
  validates :date, presence: true
  validates :ai_model, presence: true
  validates :date, uniqueness: { scope: :ai_model, message: "and model combination already exists" }
  validates :total_requests, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_cost, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :for_date, ->(date) { where(date: date) }
  scope :for_model, ->(model) { where(ai_model: model) }
  scope :recent, -> { order(date: :desc) }
  scope :this_month, -> { where(date: Date.current.all_month) }
  scope :last_30_days, -> { where(date: 30.days.ago.to_date..Date.current) }

  # Find or initialize a record for today and given model
  def self.for_today(ai_model)
    find_or_initialize_by(date: Date.current, ai_model: ai_model)
  end

  # Increment usage statistics
  def record_usage!(requests: 1, tokens: 0, cost: 0.0, generation_type: nil)
    self.total_requests += requests
    self.total_tokens += tokens
    self.total_cost += cost

    # Update breakdown by generation type
    if generation_type.present?
      self.breakdown ||= {}
      self.breakdown[generation_type] ||= { "requests" => 0, "tokens" => 0, "cost" => 0.0 }
      self.breakdown[generation_type]["requests"] += requests
      self.breakdown[generation_type]["tokens"] += tokens
      self.breakdown[generation_type]["cost"] += cost
    end

    save!
  end

  # Get total cost for a date range
  def self.total_cost_for(start_date, end_date = Date.current)
    where(date: start_date..end_date).sum(:total_cost)
  end

  # Get total tokens for a date range
  def self.total_tokens_for(start_date, end_date = Date.current)
    where(date: start_date..end_date).sum(:total_tokens)
  end

  # Get total requests for a date range
  def self.total_requests_for(start_date, end_date = Date.current)
    where(date: start_date..end_date).sum(:total_requests)
  end

  # Get daily summary for the last N days
  def self.daily_summary(days: 30)
    start_date = days.days.ago.to_date
    where(date: start_date..Date.current)
      .group(:date)
      .select(
        "date",
        "SUM(total_requests) as requests",
        "SUM(total_tokens) as tokens",
        "SUM(total_cost) as cost"
      )
      .order(date: :desc)
  end

  # Get model breakdown for current month
  def self.monthly_model_breakdown
    this_month
      .group(:ai_model)
      .select(
        "ai_model",
        "SUM(total_requests) as requests",
        "SUM(total_tokens) as tokens",
        "SUM(total_cost) as cost"
      )
  end

  # Formatted cost
  def formatted_cost
    format("$%.2f", total_cost)
  end

  # Average cost per request
  def average_cost_per_request
    return 0 if total_requests.zero?
    total_cost / total_requests
  end

  # Average tokens per request
  def average_tokens_per_request
    return 0 if total_requests.zero?
    total_tokens / total_requests
  end
end
