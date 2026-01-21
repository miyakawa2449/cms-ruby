require "rails_helper"

RSpec.describe ArticleAssociationService do
  let(:article) { create(:article) }
  let(:service) { described_class.new(article) }

  describe "#setup_for_form" do
    it "returns categories, tags, and current selections" do
      category = create(:category)
      tag = create(:tag, name: "ruby")
      article.categories << category
      article.tags << tag

      result = service.setup_for_form

      expect(result[:categories]).to include(category)
      expect(result[:available_tags]).to include(tag)
      expect(result[:selected_category_ids]).to eq([category.id])
      expect(result[:tag_names]).to include("ruby")
    end
  end

  describe "#process_associations" do
    it "sets only valid category ids" do
      valid_category = create(:category)

      service.process_associations(category_ids: [valid_category.id, 999], tag_names: nil)

      expect(article.reload.category_ids).to eq([valid_category.id])
    end

    it "creates tags and assigns them" do
      service.process_associations(category_ids: nil, tag_names: "Ruby, Rails")

      expect(article.reload.tags.map(&:name)).to contain_exactly("ruby", "rails")
    end
  end
end
