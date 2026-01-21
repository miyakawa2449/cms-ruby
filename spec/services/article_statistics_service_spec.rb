require "rails_helper"

RSpec.describe ArticleStatisticsService do
  before do
    ArticleCategory.delete_all
    ArticleTag.delete_all
    AiGeneration.delete_all
    Article.delete_all
    Category.delete_all
    Tag.delete_all
  end

  describe ".calculate" do
    it "returns counts and grouped stats" do
      allow_any_instance_of(ArticleStatisticsService).to receive(:monthly_statistics).and_return({})
      create(:article, status: "published", work_type: "github")
      create(:article, status: "draft", work_type: "external_url")
      category = create(:category, name: "Tech")
      create(:article, :published, categories: [category])

      stats = described_class.calculate

      expect(stats[:total_count]).to eq(3)
      expect(stats[:published_count]).to eq(2)
      expect(stats[:draft_count]).to eq(1)
      expect(stats[:work_statistics].keys).to include("github", "external_url")
      expect(stats[:category_statistics]["Tech"]).to be >= 1
      expect(stats[:monthly_statistics]).to be_a(Hash)
    end
  end

  describe "#index_stats" do
    it "returns grouped status counts" do
      Article.delete_all
      create(:article, status: "published")
      create(:article, status: "draft")

      stats = described_class.new.index_stats

      expect(stats[:total_count]).to eq(2)
      expect(stats[:published_count]).to eq(1)
      expect(stats[:draft_count]).to eq(1)
    end
  end
end
