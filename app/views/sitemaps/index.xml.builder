# frozen_string_literal: true

# sitemap.xml - Phase 4.4 基本SEO機能実装
xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # トップページ
  xml.url do
    xml.loc root_url
    xml.lastmod Time.current.iso8601
    xml.changefreq "daily"
    xml.priority 1.0
  end

  # My Storyページ
  xml.url do
    xml.loc my_story_url
    xml.lastmod Time.current.iso8601
    xml.changefreq "monthly"
    xml.priority 0.8
  end

  # ブログ一覧ページ
  xml.url do
    xml.loc blog_url
    xml.lastmod @articles.first&.updated_at&.iso8601 || Time.current.iso8601
    xml.changefreq "daily"
    xml.priority 0.9
  end

  # 公開記事
  @articles.each do |article|
    xml.url do
      xml.loc blog_article_url(article.slug)
      xml.lastmod article.updated_at.iso8601
      xml.changefreq "weekly"
      xml.priority 0.8
    end
  end

  # カテゴリページ（公開記事があるカテゴリのみ）
  @categories.each do |category|
    xml.url do
      xml.loc "#{blog_url}?category_id=#{category.id}"
      xml.lastmod category.articles.published.maximum(:updated_at)&.iso8601 || Time.current.iso8601
      xml.changefreq "weekly"
      xml.priority 0.6
    end
  end
end
