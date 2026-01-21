require "rails_helper"

RSpec.describe "Api::V1::Sections", type: :request do
  before do
    ActiveRecord::Base.connection.reset_pk_sequence!("sections")
  end

  describe "GET /api/v1/sections" do
    it "公開セクション一覧を取得できる" do
      section = Section.find_by(name: "about") || create(:section, name: "about", display_name: "About", is_visible: true)

      get api_v1_sections_path

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"].map { |row| row["name"] }).to include(section.name)
    end

    it "非公開セクションは含まれない" do
      hidden_name = "hidden-#{SecureRandom.hex(4)}"
      create(:section, name: hidden_name, display_name: "Hidden", is_visible: false)

      get api_v1_sections_path

      json = JSON.parse(response.body)
      expect(json["data"].map { |row| row["name"] }).not_to include(hidden_name)
    end
  end

  describe "GET /api/v1/sections/:name" do
    it "セクション詳細を取得できる" do
      section = create(:section, name: "profile", display_name: "Profile", is_visible: true)

      get api_v1_section_path(section.name)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json["data"]["name"]).to eq("profile")
    end

    it "非公開セクションは404になる" do
      section = create(:section, name: "draft", display_name: "Draft", is_visible: false)

      get api_v1_section_path(section.name)

      expect(response).to have_http_status(:not_found)
    end

    it "存在しないセクションは404になる" do
      get api_v1_section_path("missing")

      expect(response).to have_http_status(:not_found)
    end
  end
end
