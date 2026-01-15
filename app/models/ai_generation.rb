# AI generation history record
# Tracks all AI-generated content (summaries, tags, slugs, SEO meta, structures)
class AiGeneration < ApplicationRecord
  # Valid generation types
  GENERATION_TYPES = %w[summary title tags slug seo_meta structure].freeze

  # Valid statuses
  STATUSES = %w[pending completed failed].freeze

  # Associations
  belongs_to :article, optional: true
  belongs_to :admin_user, optional: true

  # Validations
  validates :generation_type, presence: true, inclusion: { in: GENERATION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :tokens_used, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :by_type, ->(type) { where(generation_type: type) }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :this_month, -> { where(created_at: Date.current.all_month) }

  # Mark as completed with output data
  def complete!(output_data, tokens: 0, cost: 0.0)
    update!(
      status: "completed",
      output_data: output_data,
      tokens_used: tokens,
      cost: cost
    )
  end

  # Mark as failed with error message
  def fail!(error_message)
    update!(
      status: "failed",
      error_message: error_message
    )
  end

  # Check if generation is complete
  def completed?
    status == "completed"
  end

  # Check if generation failed
  def failed?
    status == "failed"
  end

  # Check if generation is pending
  def pending?
    status == "pending"
  end

  # Get formatted cost
  def formatted_cost
    format("$%.4f", cost || 0)
  end

  # Class method to calculate total cost for a period
  def self.total_cost_for(start_date, end_date = Date.current)
    where(created_at: start_date..end_date.end_of_day)
      .completed
      .sum(:cost)
  end

  # Class method to calculate total tokens for a period
  def self.total_tokens_for(start_date, end_date = Date.current)
    where(created_at: start_date..end_date.end_of_day)
      .completed
      .sum(:tokens_used)
  end
end
