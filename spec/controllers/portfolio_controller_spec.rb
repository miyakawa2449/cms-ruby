require "rails_helper"

RSpec.describe PortfolioController, type: :controller do
  before do
    SectionContent.delete_all
    Section.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!("sections")
    ArticleCategory.delete_all
    ArticleTag.delete_all
    AiGeneration.delete_all
    Article.delete_all
    Category.delete_all
    Tag.delete_all
  end

  describe "GET #index" do
    it "assigns sections and recent articles" do
      visible = create(:section, name: "visible", is_visible: true, position: 0)
      create(:section_content, section: visible, is_active: true, content: { "message" => "hello" })
      create(:section, name: "hidden", is_visible: false, position: 1)

      works = create(:category, slug: "works")
      create(:article, :published, categories: [ works ])
      article = create(:article, :published, content: "searchable content")

      get :index

      expect(assigns(:sections)).to eq([visible])
      expect(assigns(:section_data)["visible"]).to eq({ "message" => "hello" })
      expect(assigns(:recent_articles)).to include(article)
    end

    it "applies search filter and sets search query" do
      create(:article, :published, content: "alpha")
      target = create(:article, :published, content: "beta keyword")

      get :index, params: { search: "keyword" }

      expect(assigns(:search_query)).to eq("keyword")
      expect(assigns(:recent_articles)).to include(target)
    end

    it "handles unexpected errors gracefully" do
      allow(Section).to receive(:includes).and_raise(StandardError, "boom")

      get :index

      expect(assigns(:sections)).to eq([])
      expect(assigns(:recent_articles)).to eq([])
    end
  end
end
