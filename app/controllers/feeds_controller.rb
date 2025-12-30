# frozen_string_literal: true

# RSS/Atomフィード提供コントローラー
# Phase 4.4: 基本SEO機能実装
class FeedsController < ApplicationController
  def rss
    load_feed_data

    respond_to do |format|
      format.rss { render layout: false }
    end
  end

  def atom
    load_feed_data

    respond_to do |format|
      format.atom { render layout: false }
    end
  end

  private

  def load_feed_data
    @articles = Article.published
                       .includes(:categories)
                       .order(published_at: :desc)
                       .limit(20)
    @site_name = SiteSetting.find_by(key: "site_title")&.value || "Tech Blog"
    @site_description = SiteSetting.find_by(key: "site_description")&.value || "技術ブログ"
  end
end
