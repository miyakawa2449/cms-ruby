require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#flash_class" do
    it "returns mapped classes for known types" do
      expect(helper.flash_class(:notice)).to include("bg-green-100")
      expect(helper.flash_class("alert")).to include("bg-red-100")
      expect(helper.flash_class(:warning)).to include("bg-yellow-100")
    end

    it "falls back to default class for unknown types" do
      expect(helper.flash_class(:unknown)).to include("bg-blue-100")
    end
  end

  describe "#environment_badge" do
    it "renders badge in development" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

      html = helper.environment_badge

      expect(html).to include("DEVELOPMENT")
      expect(html).to include("bg-green-500")
    end

    it "renders badge in staging" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("staging"))

      html = helper.environment_badge

      expect(html).to include("STAGING")
      expect(html).to include("bg-yellow-500")
    end

    it "returns nil in production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

      expect(helper.environment_badge).to be_nil
    end
  end
end
