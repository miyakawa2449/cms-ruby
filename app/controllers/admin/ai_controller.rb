# AI feature endpoints for article editing
# Provides summary generation, tag suggestions, slug generation, and SEO meta generation
class Admin::AiController < Admin::BaseController
  before_action :set_article
  before_action :check_ai_availability, only: [ :generate_summary, :suggest_tags, :generate_slug, :generate_seo_meta, :suggest_title, :suggest_structure ]

  # POST /admin/articles/:article_id/ai/suggest_title
  def suggest_title
    suggester = Ai::TitleSuggester.new(
      article: @article,
      admin_user: current_admin_user
    )

    result = suggester.suggest(
      count: (params[:count] || 3).to_i
    )

    render json: result
  end

  # POST /admin/articles/:article_id/ai/generate_summary
  def generate_summary
    generator = Ai::SummaryGenerator.new(
      article: @article,
      admin_user: current_admin_user
    )

    result = generator.generate(
      length: params[:length] || "medium",
      count: (params[:count] || 3).to_i
    )

    render json: result
  end

  # POST /admin/articles/:article_id/ai/suggest_tags
  def suggest_tags
    suggester = Ai::TagSuggester.new(
      article: @article,
      admin_user: current_admin_user
    )

    result = suggester.suggest(
      max_tags: (params[:max_tags] || 6).to_i,
      include_existing: params[:include_existing] != "false"
    )

    render json: result
  end

  # POST /admin/articles/:article_id/ai/generate_slug
  def generate_slug
    generator = Ai::SlugGenerator.new(
      article: @article,
      admin_user: current_admin_user
    )

    result = generator.generate(
      title: params[:title] || @article.title,
      count: (params[:count] || 3).to_i
    )

    render json: result
  end

  # POST /admin/articles/:article_id/ai/generate_seo_meta
  def generate_seo_meta
    generator = Ai::SeoMetaGenerator.new(
      article: @article,
      admin_user: current_admin_user
    )

    fields = params[:fields] || Ai::SeoMetaGenerator::AVAILABLE_FIELDS
    result = generator.generate(fields: Array(fields))

    render json: result
  end

  # POST /admin/ai/suggest_structure
  # Suggests article structure based on a topic
  # @param topic [String] Article topic (required)
  # @param detail_level [String] 'basic', 'detailed', or 'comprehensive' (default: 'detailed')
  # @param format [String] 'markdown' or 'json' (default: 'markdown')
  def suggest_structure
    suggester = Ai::StructureSuggester.new(admin_user: current_admin_user)

    result = suggester.suggest(
      topic: params[:topic],
      detail_level: params[:detail_level] || "detailed",
      format: params[:format] || "markdown"
    )

    render json: result
  end

  # GET /admin/ai/usage_stats
  def usage_stats
    period = params[:period] || "month"

    stats = case period
    when "today"
              Ai::UsageTracker.today
    when "month"
              Ai::UsageTracker.this_month
    else
              start_date = parse_start_date(period)
              Ai::UsageTracker.summary(start_date: start_date)
    end

    render json: { success: true, data: stats }
  end

  private

  def set_article
    return unless params[:article_id]

    @article = if params[:article_id] =~ /\A\d+\z/
                 Article.find(params[:article_id])
    else
                 Article.find_by!(slug: params[:article_id])
    end
  end

  def check_ai_availability
    return if ai_service_available?

    render json: {
      success: false,
      error: "AI機能は現在利用できません。AWS設定を確認してください。"
    }, status: :service_unavailable
  end

  def ai_service_available?
    # Check if AWS credentials are configured
    return false if Rails.env.production? && !aws_credentials_configured?
    true
  end

  def aws_credentials_configured?
    # Check for Bedrock-specific credentials first, then fall back to general AWS credentials
    bedrock_configured = ENV["AWS_BEDROCK_REGION"].present? &&
                         ENV["AWS_BEDROCK_ACCESS_KEY_ID"].present? &&
                         ENV["AWS_BEDROCK_SECRET_ACCESS_KEY"].present?

    general_configured = ENV["AWS_REGION"].present? ||
                         (ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?)

    bedrock_configured || general_configured
  end

  def parse_start_date(period)
    case period
    when "week"
      7.days.ago.to_date
    when "30days"
      30.days.ago.to_date
    else
      Date.current.beginning_of_month
    end
  end
end
