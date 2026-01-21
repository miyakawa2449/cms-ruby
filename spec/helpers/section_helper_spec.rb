require "rails_helper"

RSpec.describe SectionHelper, type: :helper do
  before do
    SectionContent.delete_all
    Section.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!("sections")
  end

  describe "#about_section" do
    it "memoizes and returns the about section" do
      section = create(:section, name: "about")

      first = helper.about_section
      second = helper.about_section

      expect(first).to eq(section)
      expect(second).to eq(section)
    end
  end

  describe "#active_sections" do
    it "returns visible sections ordered by position" do
      visible = create(:section, name: "visible", is_visible: true, position: 2)
      create(:section, name: "hidden", is_visible: false, position: 1)
      earlier = create(:section, name: "earlier", is_visible: true, position: 0)

      result = helper.active_sections

      expect(result).to eq([earlier, visible])
    end
  end

  describe "#section_active_content" do
    it "returns empty hash when no active content" do
      section = create(:section)

      expect(helper.section_active_content(section)).to eq({})
    end

    it "returns active content data when present" do
      section = create(:section)
      create(:section_content, section: section, is_active: true, content: { "key" => "value" })

      expect(helper.section_active_content(section)).to eq({ "key" => "value" })
    end

    it "handles errors and returns empty hash" do
      section = create(:section)
      allow(section).to receive(:active_content_data).and_raise(StandardError, "boom")
      allow(section).to receive(:active_content).and_return(double("active"))

      expect(helper.section_active_content(section)).to eq({})
    end
  end

  describe "#section_displayable?" do
    it "returns true for individual field sections" do
      section = create(:section, name: "hero")

      expect(helper.section_displayable?(section, {})).to eq(true)
    end

    it "returns false when no active content" do
      section = create(:section, name: "custom")

      expect(helper.section_displayable?(section, {})).to eq(false)
    end

    it "returns true when active content and data present" do
      section = create(:section, name: "custom")
      create(:section_content, section: section, is_active: true, content: { "a" => 1 })

      expect(helper.section_displayable?(section, { "a" => 1 })).to eq(true)
    end
  end
end
