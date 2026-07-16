require "rails_helper"

RSpec.describe ImageHelper, type: :helper do
  describe "#lazy_image_tag" do
    it "adds lazy loading by default" do
      html = helper.lazy_image_tag("https://example.com/test.jpg", alt: "Example")

      expect(html).to include("loading=\"lazy\"")
      expect(html).to include("decoding=\"async\"")
    end

    it "respects custom loading option" do
      html = helper.lazy_image_tag("https://example.com/test.jpg", alt: "Example", loading: "eager")

      expect(html).to include("loading=\"eager\"")
      expect(html).to include("decoding=\"async\"")
    end

    it "sets alt and class attributes" do
      html = helper.lazy_image_tag("https://example.com/test.jpg", alt: "Alt text", class: "rounded")

      expect(html).to include("alt=\"Alt text\"")
      expect(html).to include("class=\"rounded\"")
    end
  end
end
