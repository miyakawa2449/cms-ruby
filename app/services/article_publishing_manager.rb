# 記事公開ロジックの唯一の実装（S1-7 P1-6で3系統を統合）。
# 状態遷移・状態判定・予約公開のバッチをここに集約する。
# 注意: unpublish時にpublished_atは温存する（2026-07-17仕様確定。再公開しても元の公開日を維持）
class ArticlePublishingManager
  def initialize(article)
    @article = article
  end

  # Publishing status management
  # published_at の優先順: 明示指定 > 既存値（再公開時の温存） > 現在時刻（初回公開）
  def publish!(published_at: nil)
    @article.status = "published"
    @article.published_at = published_at || @article.published_at || Time.current
    save_article
  end

  def unpublish!
    @article.status = "draft"
    save_article
  end

  # コントローラ向けの結果ハッシュ版（旧ArticlePublishingServiceの置き換え）
  def publish
    publish!
    { success: true, message: "記事を公開しました。" }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, message: "公開に失敗しました。", errors: e.record.errors.full_messages }
  end

  def unpublish
    unpublish!
    { success: true, message: "記事を非公開にしました。" }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, message: "非公開化に失敗しました。", errors: e.record.errors.full_messages }
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

  private

  def save_article
    @article.save!
  end
end
