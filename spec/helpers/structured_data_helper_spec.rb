# frozen_string_literal: true

require "rails_helper"

RSpec.describe StructuredDataHelper, type: :helper do
  describe "#faq_schema" do
    let(:faqs) do
      [
        { question: "質問1", answer: "回答1" },
        { question: "質問2", answer: "回答2" }
      ]
    end

    it "generates valid FAQ schema" do
      schema = helper.faq_schema(faqs)

      expect(schema["@context"]).to eq("https://schema.org")
      expect(schema["@type"]).to eq("FAQPage")
      expect(schema["mainEntity"]).to be_an(Array)
      expect(schema["mainEntity"].size).to eq(2)
    end

    it "includes correct question and answer structure" do
      schema = helper.faq_schema(faqs)
      first_item = schema["mainEntity"].first

      expect(first_item["@type"]).to eq("Question")
      expect(first_item["name"]).to eq("質問1")
      expect(first_item["acceptedAnswer"]["@type"]).to eq("Answer")
      expect(first_item["acceptedAnswer"]["text"]).to eq("回答1")
    end

    it "returns nil for empty faqs" do
      expect(helper.faq_schema([])).to be_nil
      expect(helper.faq_schema(nil)).to be_nil
    end
  end

  describe "#how_to_schema" do
    let(:how_to_options) do
      {
        name: "Railsアプリを作る方法",
        description: "Rails 8でアプリを作成する手順",
        total_time: "PT1H",
        steps: [
          { name: "Railsをインストール", text: "gem install railsを実行" },
          { name: "アプリ作成", text: "rails newを実行" }
        ]
      }
    end

    it "generates valid HowTo schema" do
      schema = helper.how_to_schema(how_to_options)

      expect(schema["@context"]).to eq("https://schema.org")
      expect(schema["@type"]).to eq("HowTo")
      expect(schema["name"]).to eq("Railsアプリを作る方法")
      expect(schema["description"]).to eq("Rails 8でアプリを作成する手順")
      expect(schema["totalTime"]).to eq("PT1H")
    end

    it "includes step positions" do
      schema = helper.how_to_schema(how_to_options)

      expect(schema["step"].first["position"]).to eq(1)
      expect(schema["step"].last["position"]).to eq(2)
    end

    it "includes optional fields when provided" do
      options = how_to_options.merge(
        image: "https://example.com/image.jpg",
        cost: 500,
        supplies: [ "APIキー", "開発環境" ],
        tools: [ "Ruby", "Rails" ]
      )

      schema = helper.how_to_schema(options)

      expect(schema["image"]).to eq("https://example.com/image.jpg")
      expect(schema["estimatedCost"]["value"]).to eq(500)
      expect(schema["estimatedCost"]["currency"]).to eq("JPY")
      expect(schema["supply"].size).to eq(2)
      expect(schema["tool"].size).to eq(2)
    end

    it "returns nil when name is blank" do
      expect(helper.how_to_schema(name: nil, steps: how_to_options[:steps])).to be_nil
    end

    it "returns nil when steps are blank" do
      expect(helper.how_to_schema(name: "Test", steps: [])).to be_nil
    end
  end

  describe "#breadcrumb_schema" do
    let(:breadcrumbs) do
      [
        [ "ホーム", "https://example.com/" ],
        [ "ブログ", "https://example.com/blog" ],
        [ "記事タイトル", nil ]
      ]
    end

    it "generates valid BreadcrumbList schema" do
      schema = helper.breadcrumb_schema(breadcrumbs)

      expect(schema["@context"]).to eq("https://schema.org")
      expect(schema["@type"]).to eq("BreadcrumbList")
      expect(schema["itemListElement"]).to be_an(Array)
      expect(schema["itemListElement"].size).to eq(3)
    end

    it "includes correct positions" do
      schema = helper.breadcrumb_schema(breadcrumbs)

      schema["itemListElement"].each_with_index do |item, index|
        expect(item["position"]).to eq(index + 1)
      end
    end

    it "includes item URL only when present" do
      schema = helper.breadcrumb_schema(breadcrumbs)
      items = schema["itemListElement"]

      expect(items[0]["item"]).to eq("https://example.com/")
      expect(items[1]["item"]).to eq("https://example.com/blog")
      expect(items[2]).not_to have_key("item")
    end

    it "returns nil for empty breadcrumbs" do
      expect(helper.breadcrumb_schema([])).to be_nil
      expect(helper.breadcrumb_schema(nil)).to be_nil
    end
  end

  describe "#organization_schema" do
    before do
      allow(ENV).to receive(:fetch).with("SITE_URL", anything).and_return("https://example.com")
      allow(ENV).to receive(:fetch).with("SITE_NAME", anything).and_return("Test Site")
    end

    it "generates valid Organization schema with defaults" do
      schema = helper.organization_schema

      expect(schema["@context"]).to eq("https://schema.org")
      expect(schema["@type"]).to eq("Organization")
      expect(schema["name"]).to eq("Test Site")
      expect(schema["url"]).to eq("https://example.com")
    end

    it "uses provided options over defaults" do
      schema = helper.organization_schema(
        name: "Custom Org",
        url: "https://custom.com"
      )

      expect(schema["name"]).to eq("Custom Org")
      expect(schema["url"]).to eq("https://custom.com")
    end

    it "includes optional fields when provided" do
      schema = helper.organization_schema(
        logo: "https://example.com/logo.png",
        description: "Test description",
        email: "test@example.com",
        social: {
          twitter: "https://twitter.com/test",
          github: "https://github.com/test"
        }
      )

      expect(schema["logo"]["@type"]).to eq("ImageObject")
      expect(schema["description"]).to eq("Test description")
      expect(schema["contactPoint"]["email"]).to eq("test@example.com")
      expect(schema["sameAs"]).to include("https://twitter.com/test")
      expect(schema["sameAs"]).to include("https://github.com/test")
    end
  end

  describe "#person_schema" do
    it "generates valid Person schema" do
      schema = helper.person_schema(
        name: "宮川 剛",
        url: "https://example.com",
        job_title: "シニアエンジニア"
      )

      expect(schema["@context"]).to eq("https://schema.org")
      expect(schema["@type"]).to eq("Person")
      expect(schema["name"]).to eq("宮川 剛")
      expect(schema["jobTitle"]).to eq("シニアエンジニア")
    end

    it "returns nil when name is blank" do
      expect(helper.person_schema(name: nil)).to be_nil
      expect(helper.person_schema(name: "")).to be_nil
    end

    it "includes social links when provided" do
      schema = helper.person_schema(
        name: "Test",
        social: { twitter: "https://twitter.com/test" }
      )

      expect(schema["sameAs"]).to include("https://twitter.com/test")
    end
  end

  describe "#website_schema" do
    before do
      allow(ENV).to receive(:fetch).with("SITE_URL", anything).and_return("https://example.com")
      allow(ENV).to receive(:fetch).with("SITE_NAME", anything).and_return("Test Site")
    end

    it "generates valid WebSite schema" do
      schema = helper.website_schema

      expect(schema["@context"]).to eq("https://schema.org")
      expect(schema["@type"]).to eq("WebSite")
      expect(schema["name"]).to eq("Test Site")
      expect(schema["url"]).to eq("https://example.com")
    end

    it "includes search action when search_url provided" do
      schema = helper.website_schema(
        search_url: "https://example.com/search?q={search_term_string}"
      )

      expect(schema["potentialAction"]["@type"]).to eq("SearchAction")
      expect(schema["potentialAction"]["target"]["urlTemplate"]).to eq(
        "https://example.com/search?q={search_term_string}"
      )
    end
  end

  describe "#structured_data_tag" do
    it "generates script tag with JSON-LD" do
      schema = { "@type" => "Test" }
      html = helper.structured_data_tag(schema)

      expect(html).to include('type="application/ld+json"')
      expect(html).to include('"@type":"Test"')
    end

    it "returns empty string for nil schema" do
      expect(helper.structured_data_tag(nil)).to eq("")
    end

    it "handles array of schemas" do
      schemas = [
        { "@type" => "Test1" },
        { "@type" => "Test2" }
      ]
      html = helper.structured_data_tag(schemas)

      expect(html).to include("Test1")
      expect(html).to include("Test2")
    end

    it "escapes dangerous sequences to prevent script injection" do
      schema = {
        "@type" => "FAQPage",
        "mainEntity" => [
          {
            "@type" => "Question",
            "name" => "Q",
            "acceptedAnswer" => {
              "@type" => "Answer",
              "text" => "</script><script>alert('xss')</script>"
            }
          }
        ]
      }

      html = helper.structured_data_tag(schema)

      expect(html).to include('type="application/ld+json"')
      expect(html).to include("\\u003c/script\\u003e")
      expect(html).not_to include("</script><script>")
    end

    it "preserves long and unicode text" do
      long_text = "あ" * 5000 + "🚀"
      schema = { "@type" => "Test", "text" => long_text }

      html = helper.structured_data_tag(schema)

      expect(html).to include("Test")
      expect(html).to include("🚀")
      expect(html).to include(long_text[0, 100])
    end
  end

  describe "#combined_structured_data_tag" do
    it "combines multiple schemas into single tag" do
      schema1 = { "@type" => "Schema1" }
      schema2 = { "@type" => "Schema2" }

      html = helper.combined_structured_data_tag(schema1, schema2)

      expect(html).to include("Schema1")
      expect(html).to include("Schema2")
    end

    it "filters out nil schemas" do
      schema = { "@type" => "Test" }
      html = helper.combined_structured_data_tag(schema, nil)

      expect(html).to include("Test")
      expect(html).not_to include("null")
    end

    it "returns empty string when all schemas are nil" do
      expect(helper.combined_structured_data_tag(nil, nil)).to eq("")
    end
  end
end
