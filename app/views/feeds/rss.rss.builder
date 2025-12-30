# frozen_string_literal: true

# RSS 2.0 フィード - Phase 4.4 基本SEO機能実装
xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title @site_name
    xml.description @site_description
    xml.link blog_url
    xml.language "ja"
    xml.lastBuildDate @articles.first&.published_at&.rfc822 || Time.current.rfc822
    xml.tag!("atom:link", href: feed_rss_url(format: :rss), rel: "self", type: "application/rss+xml")

    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.link blog_article_url(article.slug)
        xml.description article.excerpt.presence || truncate(strip_tags(article.content), length: 200)
        xml.pubDate article.published_at.rfc822
        xml.guid blog_article_url(article.slug), isPermaLink: "true"

        # カテゴリ
        article.categories.each do |category|
          xml.category category.name
        end
      end
    end
  end
end
