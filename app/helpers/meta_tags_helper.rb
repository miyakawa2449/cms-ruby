module MetaTagsHelper
  # MetaTagsServiceへの委譲メソッド
  def article_meta_tags(article)
    meta_tags_service.article_meta_tags(article)
  end

  def portfolio_meta_tags
    meta_tags_service.portfolio_meta_tags
  end

  def blog_top_meta_tags
    meta_tags_service.blog_top_meta_tags
  end

  def category_meta_tags(category)
    meta_tags_service.category_meta_tags(category)
  end

  # SiteAssetsServiceへの委譲メソッド
  def site_logo(options = {})
    site_assets_service.site_logo(options)
  end

  def favicon_tags
    site_assets_service.favicon_tags
  end

  def favicon_icon_tags
    site_assets_service.favicon_icon_tags
  end

  # 非推奨のメソッドとして残す（後方互換性）
  def page_meta_tags(options = {})
    Rails.logger.warn "page_meta_tags is deprecated. Use specific meta tag methods instead."
    meta_tags_service.send(:build_meta_tags, options)
  end

  private

  def meta_tags_service
    @meta_tags_service ||= MetaTagsService.new(request)
  end

  def site_assets_service
    @site_assets_service ||= SiteAssetsService.new(request)
  end
end
