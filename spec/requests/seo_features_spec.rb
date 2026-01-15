# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SEO Features", type: :request do
  # テスト用ホスト設定
  before do
    host! "localhost"
  end

  describe "GET /sitemap.xml" do
    let!(:published_article) { create(:article, :published) }
    let!(:draft_article) { create(:article, status: "draft") }

    it "returns successful response" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:success)
    end

    it "returns XML content type" do
      get "/sitemap.xml"
      expect(response.content_type).to include("application/xml")
    end

    it "includes published articles" do
      get "/sitemap.xml"
      expect(response.body).to include(published_article.slug)
    end

    it "excludes draft articles" do
      get "/sitemap.xml"
      expect(response.body).not_to include(draft_article.slug)
    end

    it "includes static pages" do
      get "/sitemap.xml"
      expect(response.body).to include("/my-story")
      expect(response.body).to include("/blog")
    end
  end

  describe "GET /feed.rss" do
    let!(:articles) { create_list(:article, 3, :published) }

    it "returns successful response" do
      get "/feed.rss"
      expect(response).to have_http_status(:success)
    end

    it "returns RSS content type" do
      get "/feed.rss"
      expect(response.content_type).to include("application/rss+xml")
    end

    it "includes published articles" do
      get "/feed.rss"
      articles.each do |article|
        expect(response.body).to include(article.title)
      end
    end

    it "limits to 20 articles" do
      create_list(:article, 25, :published)
      get "/feed.rss"
      # Count <item> tags in RSS
      expect(response.body.scan("<item>").count).to be <= 20
    end
  end

  describe "GET /feed.atom" do
    let!(:articles) { create_list(:article, 3, :published) }

    it "returns successful response" do
      get "/feed.atom"
      expect(response).to have_http_status(:success)
    end

    it "returns Atom content type" do
      get "/feed.atom"
      expect(response.content_type).to include("application/atom+xml")
    end

    it "includes published articles" do
      get "/feed.atom"
      articles.each do |article|
        expect(response.body).to include(article.title)
      end
    end
  end

  describe "robots.txt file" do
    let(:robots_txt_path) { Rails.root.join("public/robots.txt") }

    it "exists" do
      expect(File.exist?(robots_txt_path)).to be true
    end

    it "includes sitemap location" do
      content = File.read(robots_txt_path)
      expect(content).to include("Sitemap:")
    end

    it "disallows admin paths" do
      content = File.read(robots_txt_path)
      expect(content).to include("Disallow: /admin")
    end

    it "allows public pages" do
      content = File.read(robots_txt_path)
      expect(content).to include("Allow: /")
    end
  end

  describe "Blog page feed links" do
    it "includes RSS and Atom links in head" do
      get "/blog"
      expect(response.body).to include('type="application/rss+xml"')
      expect(response.body).to include('type="application/atom+xml"')
    end

    it "includes feed subscription section in sidebar" do
      get "/blog"
      expect(response.body).to include("購読する")
      expect(response.body).to include("RSS Feed")
      expect(response.body).to include("Atom Feed")
    end
  end
end
