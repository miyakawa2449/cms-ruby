require "rails_helper"

RSpec.describe SiteSettingTypeManager do
  describe ".setting_config" do
    it "returns config for known settings" do
      config = described_class.setting_config(:site_title)

      expect(config[:type]).to eq("text")
      expect(config[:default]).to be_present
    end

    it "returns nil for unknown settings" do
      expect(described_class.setting_config(:unknown)).to be_nil
    end
  end

  describe ".valid_type?" do
    it "accepts valid types" do
      expect(described_class.valid_type?("text")).to eq(true)
      expect(described_class.valid_type?("image")).to eq(true)
    end

    it "rejects invalid types" do
      expect(described_class.valid_type?("other")).to eq(false)
    end
  end

  describe ".validate_setting_config" do
    it "returns errors for blank text values" do
      result = described_class.validate_setting_config(:site_title, "", "text")

      expect(result[:valid]).to eq(false)
      expect(result[:errors]).to include("Value cannot be blank")
    end

    it "returns errors for mismatched types" do
      result = described_class.validate_setting_config(:site_title, "ok", "image")

      expect(result[:valid]).to eq(false)
      expect(result[:errors]).to include("Expected type 'text', got 'image'")
    end
  end

  describe ".settings_by_type" do
    it "groups settings by type" do
      grouped = described_class.settings_by_type

      expect(grouped.keys).to include("text", "image")
    end
  end
end
