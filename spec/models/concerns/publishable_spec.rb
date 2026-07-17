# frozen_string_literal: true

require "rails_helper"

# S1-7 P1-6でvisibleスコープのみに縮小（記事系ロジックはArticlePublishingManagerへ）
RSpec.describe Publishable do
  describe ".visible" do
    it "is_visibleがtrueのレコードのみ返す" do
      visible_section = create(:section, is_visible: true)
      create(:section, is_visible: false)

      expect(Section.visible).to contain_exactly(visible_section)
    end
  end
end
