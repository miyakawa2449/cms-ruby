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

  describe "#lazy_attachment_image" do
    it "returns nil when attachment is missing" do
      article = create(:article)

      expect(helper.lazy_attachment_image(article.thumbnail_image)).to be_nil
    end

    it "renders image tag for attached file" do
      article = create(:article)
      file = Rails.root.join("spec/fixtures/files/test_image.jpg")
      article.thumbnail_image.attach(
        io: File.open(file),
        filename: "test_image.jpg",
        content_type: "image/jpeg"
      )

      html = helper.lazy_attachment_image(article.thumbnail_image, nil, alt: "Thumb")

      expect(html).to include("loading=\"lazy\"")
      expect(html).to include("alt=\"Thumb\"")
    end
  end

  describe "#lazy_image_with_placeholder" do
    it "renders placeholder and data-src when provided" do
      html = helper.lazy_image_with_placeholder(
        "https://example.com/full.jpg",
        placeholder: "https://example.com/placeholder.jpg",
        alt: "Placeholder"
      )

      expect(html).to include("src=\"https://example.com/placeholder.jpg\"")
      expect(html).to include("data-src=\"https://example.com/full.jpg\"")
    end

    it "renders source directly when no placeholder is provided" do
      html = helper.lazy_image_with_placeholder(
        "https://example.com/full.jpg",
        alt: "Full"
      )

      expect(html).to include("src=\"https://example.com/full.jpg\"")
      expect(html).not_to include("data-src=")
    end
  end
end
