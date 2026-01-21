require "rails_helper"

RSpec.describe "Api::V1::Articles", type: :request do
  describe "GET /api/v1/articles" do
    it "記事一覧を取得できる" do
      articles = create_list(:article, 3, :published)

      get api_v1_articles_path

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["status"]).to eq("success")
      titles = json["data"].map { |row| row["title"] }
      expect(titles).to include(*articles.map(&:title))
    end

    it "ページネーションが機能する" do
      create_list(:article, 15, :published)

      get api_v1_articles_path, params: { page: 2, per_page: 10 }

      json = JSON.parse(response.body)
      expect(json["data"].length).to be <= 10
      expect(json["meta"]["pagination"]["current_page"]).to eq(2)
    end

    it "カテゴリでフィルタできる" do
      category = create(:category)
      article = create(:article, :published, categories: [ category ])
      create(:article, :published)

      get api_v1_articles_path, params: { category_id: category.id }

      json = JSON.parse(response.body)
      expect(json["data"].map { |row| row["id"] }).to include(article.id)
    end

    it "タグでフィルタできる" do
      tag = create(:tag)
      article = create(:article, :published, tags: [ tag ])
      create(:article, :published)

      get api_v1_articles_path, params: { tag_id: tag.id }

      json = JSON.parse(response.body)
      expect(json["data"].map { |row| row["id"] }).to include(article.id)
    end

    it "検索クエリでフィルタできる" do
      article = create(:article, :published, title: "Ruby Search", content: "Ruby content")
      create(:article, :published, title: "Other", content: "Different")

      get api_v1_articles_path, params: { search: "Ruby" }

      json = JSON.parse(response.body)
      expect(json["data"].map { |row| row["title"] }).to include(article.title)
    end

    it "タイトルでソートできる" do
      article_b = create(:article, :published, title: "B Title")
      article_a = create(:article, :published, title: "A Title")

      get api_v1_articles_path, params: { sort: "title" }

      json = JSON.parse(response.body)
      ids = json["data"].map { |item| item["id"] }
      expect(ids.index(article_a.id)).to be < ids.index(article_b.id)
    end

    it "作成日でソートできる" do
      article_old = create(:article, :published, title: "Old", created_at: 2.days.ago)
      article_new = create(:article, :published, title: "New", created_at: 1.day.ago)

      get api_v1_articles_path, params: { sort: "created_at" }

      json = JSON.parse(response.body)
      ids = json["data"].map { |item| item["id"] }
      expect(ids.index(article_old.id)).to be < ids.index(article_new.id)
    end
  end

  describe "GET /api/v1/articles/:slug" do
    it "スラッグで記事詳細を取得できる" do
      article = create(:article, :published, slug: "api-article")

      get api_v1_article_path(article.slug)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"]["slug"]).to eq("api-article")
    end

    it "IDで記事詳細を取得できる" do
      article = create(:article, :published)

      get api_v1_article_path(article.id)

      json = JSON.parse(response.body)
      expect(json["data"]["id"]).to eq(article.id)
    end

    it "非公開記事は404になる" do
      article = create(:article, :draft, slug: "draft-article")

      get api_v1_article_path(article.slug)

      expect(response).to have_http_status(:not_found)
    end
  end
end
