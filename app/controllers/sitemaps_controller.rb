# frozen_string_literal: true

# Sitemap.xml自動生成コントローラー
# Phase 4.4: 基本SEO機能実装
class SitemapsController < ApplicationController
  def index
    @articles = Article.published.order(updated_at: :desc)
    @categories = Category.with_published_articles.order(:name)

    respond_to do |format|
      format.xml
    end
  end
end
