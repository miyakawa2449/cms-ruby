# frozen_string_literal: true

# Atom 1.0 フィード - Phase 4.4 基本SEO機能実装
xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  xml.title @site_name
  xml.subtitle @site_description
  xml.link href: blog_url
  xml.link href: feed_atom_url(format: :atom), rel: "self", type: "application/atom+xml"
  xml.id blog_url
  xml.updated @articles.first&.updated_at&.iso8601 || Time.current.iso8601
  xml.author do
    xml.name @site_name
  end

  @articles.each do |article|
    xml.entry do
      xml.title article.title
      xml.link href: blog_article_url(article.slug)
      xml.id blog_article_url(article.slug)
      xml.published article.published_at.iso8601
      xml.updated article.updated_at.iso8601
      xml.summary article.excerpt.presence || truncate(strip_tags(article.content), length: 200)

      # カテゴリ
      article.categories.each do |category|
        xml.category term: category.slug, label: category.name
      end
    end
  end
end
