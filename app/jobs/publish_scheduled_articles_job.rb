class PublishScheduledArticlesJob < ApplicationJob
  queue_as :default

  # 予約時刻（published_at）を過ぎた予約投稿記事を公開する。
  # recurring.yml により5分間隔で実行される。
  def perform
    ArticlePublishingManager.publish_scheduled_articles!
  end
end
