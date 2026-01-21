require "rails_helper"

RSpec.describe "Api::V1::Tags", type: :request do
  describe "GET /api/v1/tags" do
    it "タグ一覧を取得できる" do
      create(:tag, name: "Ruby", slug: "ruby", article_count: 2)

      get api_v1_tags_path

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"].map { |row| row["name"] }).to include("Ruby")
    end

    it "検索クエリで絞り込める" do
      create(:tag, name: "Ruby", slug: "ruby", article_count: 1)
      create(:tag, name: "Rails", slug: "rails", article_count: 1)

      get api_v1_tags_path, params: { search: "Ruby" }

      json = JSON.parse(response.body)
      expect(json["data"].map { |row| row["name"] }).to include("Ruby")
    end
  end

  describe "GET /api/v1/tags/:id" do
    it "タグ詳細を取得できる" do
      tag = create(:tag, article_count: 1)

      get api_v1_tag_path(tag.id)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"]["id"]).to eq(tag.id)
    end

    it "記事が存在しないタグは404になる" do
      tag = create(:tag, article_count: 0)

      get api_v1_tag_path(tag.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/tags/:id/articles" do
    it "タグの記事一覧を取得できる" do
      tag = create(:tag, article_count: 1)
      create(:article, :published, tags: [ tag ])

      get articles_api_v1_tag_path(tag.id)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"].length).to eq(1)
    end
  end
end
