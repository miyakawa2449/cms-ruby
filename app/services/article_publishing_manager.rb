class ArticlePublishingManager
  def initialize(article)
    @article = article
  end

  # Publishing status management
  def publish!(published_at: Time.current)
    @article.status = "published"
    @article.published_at = published_at
    save_article
  end

  def unpublish!
    @article.status = "draft"
    save_article
  end

  def archive!
    @article.status = "archived"
    save_article
  end

  def schedule!(published_at:)
    raise ArgumentError, "Published date must be in the future" if published_at <= Time.current

    @article.status = "scheduled"
    @article.published_at = published_at
    save_article
  end

  def reschedule!(new_published_at:)
    raise ArgumentError, "Article must be scheduled" unless @article.status == "scheduled"
    raise ArgumentError, "Published date must be in the future" if new_published_at <= Time.current

    @article.published_at = new_published_at
    save_article
  end

  # Status checks
  def published?
    @article.status == "published" &&
    @article.published_at.present? &&
    @article.published_at <= Time.current
  end

  def draft?
    @article.status == "draft"
  end

  def scheduled?
    @article.status == "scheduled" &&
    @article.published_at.present? &&
    @article.published_at > Time.current
  end

  def archived?
    @article.status == "archived"
  end

  def publishable?
    return false if @article.title.blank? || @article.content.blank?
    return false unless @article.admin_user.present?

    # 必要な関連データがあるかチェック
    @article.categories.any?
  end

  # Time-based status checks
  def overdue?
    scheduled? && @article.published_at < Time.current
  end

  def published_recently?(days: 7)
    return false unless published?
    @article.published_at > days.days.ago
  end

  def needs_review?
    return false unless published?
    # 6ヶ月以上前の記事は見直しが必要かもしれない
    @article.published_at < 6.months.ago
  end

  # Bulk operations for scheduled content
  def self.publish_scheduled_articles!
    Article.where(status: "scheduled")
           .where("published_at <= ?", Time.current)
           .find_each do |article|
      manager = new(article)
      begin
        # published_at は予約時刻を維持する（実行時刻で上書きしない）
        manager.publish!(published_at: article.published_at)
        Rails.logger.info "Published scheduled article: #{article.title} (ID: #{article.id})"
      rescue => e
        Rails.logger.error "Failed to publish article #{article.id}: #{e.message}"
      end
    end
  end

  # Publishing workflow helpers
  def status_display
    case @article.status
    when "draft"
      "下書き"
    when "published"
      published? ? "公開中" : "公開予定"
    when "scheduled"
      "予約投稿（#{@article.published_at&.strftime('%Y/%m/%d %H:%M')}）"
    when "archived"
      "アーカイブ"
    else
      @article.status&.humanize || "不明"
    end
  end

  def can_publish?
    %w[draft scheduled].include?(@article.status) && publishable?
  end

  def can_unpublish?
    published?
  end

  def can_schedule?
    %w[draft published].include?(@article.status)
  end

  def can_archive?
    !archived?
  end

  # Analytics and metrics helpers
  def days_since_published
    return nil unless published?
    (Time.current - @article.published_at).to_i / 1.day
  end

  def publishing_analytics
    {
      status: @article.status,
      published_at: @article.published_at,
      days_since_published: days_since_published,
      is_recent: published_recently?,
      needs_review: needs_review?,
      is_overdue: overdue?
    }
  end

  # Validation helpers
  def validate_publishing_requirements
    errors = []

    errors << "Title is required" if @article.title.blank?
    errors << "Content is required" if @article.content.blank?
    errors << "Author is required" unless @article.admin_user.present?
    errors << "At least one category is required" unless @article.categories.any?

    if @article.status == "scheduled"
      if @article.published_at.blank?
        errors << "Published date is required for scheduled articles"
      elsif @article.published_at <= Time.current
        errors << "Published date must be in the future for scheduled articles"
      end
    end

    errors
  end

  def valid_for_publishing?
    validate_publishing_requirements.empty?
  end

  private

  def save_article
    @article.save!
  end

end
