require "rails_helper"

RSpec.describe MarkdownHelper, type: :helper do
  describe "#markdown" do
    it "renders markdown content" do
      html = helper.markdown("**Bold**")

      expect(html).to include("<strong>Bold</strong>")
    end

    it "returns empty string for blank input" do
      expect(helper.markdown("")).to eq("")
    end

    it "returns html_safe output so views render HTML instead of escaped tags" do
      # サニタイズ済みHTMLをhtml_safeにしないと、ビューで <p>...</p> が文字として表示される
      expect(helper.markdown("**Bold**")).to be_html_safe
    end
  end

  describe "#markdown_with_highlight" do
    it "renders fenced code blocks with classes" do
      html = helper.markdown_with_highlight("```ruby\nputs 'hi'\n```")

      expect(html).to include("puts")
    end
  end

  describe "#safe_markdown" do
    it "returns html_safe output" do
      expect(helper.safe_markdown("*excerpt*")).to be_html_safe
    end

    it "returns simple formatted text when markdown fails" do
      allow(helper).to receive(:markdown).and_raise(StandardError, "boom")

      html = helper.safe_markdown("line")

      expect(html).to include("line")
    end
  end

  describe "#markdown_with_ogp_cards" do
    it "replaces isolated URL with OGP card on success" do
      result = instance_double("OgpResult", success?: true, data: { title: "Title" })
      allow(OgpFetcherService).to receive(:new).and_return(instance_double(OgpFetcherService, fetch: result))
      allow(ApplicationController).to receive(:render).and_return("<div>OGP</div>")

      html = helper.markdown_with_ogp_cards("https://example.com")

      expect(html).to include("<div>OGP</div>")
      expect(html).not_to include(%(<a href="https://example.com">))
    end

    it "renders plain link when OGP fetch fails" do
      result = instance_double("OgpResult", success?: false, data: {})
      allow(OgpFetcherService).to receive(:new).and_return(instance_double(OgpFetcherService, fetch: result))

      html = helper.markdown_with_ogp_cards("https://example.com")

      expect(html).to include("https://example.com")
    end
  end
end
