require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  before do
    host! "localhost"
  end

  describe "GET /api/v1/categories" do
    it "カテゴリツリーを取得できる" do
      parent = create(:category, name: "親カテゴリ", slug: "parent")
      child = create(:category, name: "子カテゴリ", slug: "child", parent: parent, article_count: 1)
      parent.update_column(:article_count, 0)

      get api_v1_categories_path

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      parent_json = json["data"].find { |row| row["id"] == parent.id }
      expect(parent_json["children"].map { |row| row["id"] }).to include(child.id)
    end

    it "フラット表示でカテゴリ一覧を取得できる" do
      create(:category, name: "公開カテゴリ", slug: "public", article_count: 2)

      get api_v1_categories_path, params: { flat: "true" }

      json = JSON.parse(response.body)
      expect(json["data"].map { |row| row["name"] }).to include("公開カテゴリ")
    end
  end

  describe "GET /api/v1/categories/:id" do
    it "カテゴリ詳細を取得できる" do
      category = create(:category, article_count: 1)

      get api_v1_category_path(category)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"]["id"]).to eq(category.id)
    end

    it "記事が存在しないカテゴリは404になる" do
      category = create(:category, article_count: 0)

      get api_v1_category_path(category)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/categories/:id/articles" do
    it "カテゴリの記事一覧を取得できる" do
      category = create(:category, article_count: 1)
      create(:article, :published, categories: [ category ])

      get articles_api_v1_category_path(category)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"].length).to eq(1)
    end
  end
end
