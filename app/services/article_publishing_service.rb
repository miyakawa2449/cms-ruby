# frozen_string_literal: true

# 記事の公開・非公開管理を担当するサービス
class ArticlePublishingService
  attr_reader :article, :errors

  def initialize(article)
    @article = article
    @errors = []
  end

  def publish
    if @article.update(status: 'published', published_at: Time.current)
      { success: true, message: "記事を公開しました。" }
    else
      @errors.concat(@article.errors.full_messages)
      { success: false, message: "公開に失敗しました。", errors: @errors }
    end
  end

  def unpublish
    if @article.update(status: 'draft', published_at: nil)
      { success: true, message: "記事を非公開にしました。" }
    else
      @errors.concat(@article.errors.full_messages)
      { success: false, message: "非公開化に失敗しました。", errors: @errors }
    end
  end

  def toggle_publish
    if @article.published?
      unpublish
    else
      publish
    end
  end

  def schedule_publish(scheduled_at)
    if @article.update(status: 'scheduled', published_at: scheduled_at)
      { success: true, message: "記事の公開予約をしました。" }
    else
      @errors.concat(@article.errors.full_messages)
      { success: false, message: "公開予約に失敗しました。", errors: @errors }
    end
  end
end