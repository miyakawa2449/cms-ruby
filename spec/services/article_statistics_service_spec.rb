require "rails_helper"

RSpec.describe ArticleStatisticsService do
  # calculate系はgroupdate gem不在で実行不能な未使用コードだったためS1-7 P0-2で削除。
  # 使用中のindex_stats（admin記事一覧のヘッダー統計）のみ残す

  describe "#index_stats" do
    before do
      ArticleCategory.delete_all
      ArticleTag.delete_all
      AiGeneration.delete_all
      Article.delete_all
    end

    it "returns grouped status counts" do
      create(:article, status: "published")
      create(:article, status: "draft")

      stats = described_class.new.index_stats

      expect(stats[:total_count]).to eq(2)
      expect(stats[:published_count]).to eq(1)
      expect(stats[:draft_count]).to eq(1)
    end
  end
end
