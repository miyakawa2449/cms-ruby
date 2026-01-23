# frozen_string_literal: true

# Helper for generating Schema.org structured data (JSON-LD)
# Supports FAQ, HowTo, BreadcrumbList, and Organization schemas
module StructuredDataHelper
  # Generate FAQ Schema (FAQPage)
  # @param faqs [Array<Hash>] Array of FAQ items with :question and :answer keys
  # @return [Hash] JSON-LD structured data for FAQ
  #
  # Example:
  #   faqs = [
  #     { question: "質問1", answer: "回答1" },
  #     { question: "質問2", answer: "回答2" }
  #   ]
  #   faq_schema(faqs)
  def faq_schema(faqs)
    return nil if faqs.blank?

    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => faqs.map do |faq|
        {
          "@type" => "Question",
          "name" => faq[:question],
          "acceptedAnswer" => {
            "@type" => "Answer",
            "text" => faq[:answer]
          }
        }
      end
    }
  end

  # Generate HowTo Schema
  # @param options [Hash] HowTo data
  # @option options [String] :name Title of the how-to
  # @option options [String] :description Description
  # @option options [String] :image Image URL (optional)
  # @option options [String] :total_time ISO 8601 duration (e.g., "PT2H" for 2 hours)
  # @option options [Integer] :cost Estimated cost (optional)
  # @option options [String] :currency Currency code (default: "JPY")
  # @option options [Array<String>] :supplies Required supplies (optional)
  # @option options [Array<String>] :tools Required tools (optional)
  # @option options [Array<Hash>] :steps Array of step hashes with :name, :text, :url, :image keys
  # @return [Hash] JSON-LD structured data for HowTo
  #
  # Example:
  #   how_to_schema(
  #     name: "Railsアプリを作る方法",
  #     description: "Rails 8でアプリを作成する手順",
  #     total_time: "PT1H",
  #     steps: [
  #       { name: "Railsをインストール", text: "gem install railsを実行" },
  #       { name: "アプリ作成", text: "rails newを実行" }
  #     ]
  #   )
  def how_to_schema(options)
    return nil if options[:name].blank? || options[:steps].blank?

    schema = {
      "@context" => "https://schema.org",
      "@type" => "HowTo",
      "name" => options[:name],
      "description" => options[:description]
    }

    # Optional fields
    schema["image"] = options[:image] if options[:image].present?
    schema["totalTime"] = options[:total_time] if options[:total_time].present?

    if options[:cost].present?
      schema["estimatedCost"] = {
        "@type" => "MonetaryAmount",
        "currency" => options[:currency] || "JPY",
        "value" => options[:cost]
      }
    end

    if options[:supplies].present?
      schema["supply"] = options[:supplies].map do |supply|
        {
          "@type" => "HowToSupply",
          "name" => supply
        }
      end
    end

    if options[:tools].present?
      schema["tool"] = options[:tools].map do |tool|
        {
          "@type" => "HowToTool",
          "name" => tool
        }
      end
    end

    schema["step"] = options[:steps].each_with_index.map do |step, index|
      step_data = {
        "@type" => "HowToStep",
        "position" => index + 1,
        "name" => step[:name],
        "text" => step[:text]
      }
      step_data["url"] = step[:url] if step[:url].present?
      step_data["image"] = step[:image] if step[:image].present?
      step_data
    end

    schema
  end

  # Generate BreadcrumbList Schema
  # @param items [Array<Array>] Array of [name, url] pairs
  # @return [Hash] JSON-LD structured data for BreadcrumbList
  #
  # Example:
  #   breadcrumb_schema([
  #     ["ホーム", root_url],
  #     ["ブログ", blog_url],
  #     ["記事タイトル", nil]  # nil for current page
  #   ])
  def breadcrumb_schema(items)
    return nil if items.blank?

    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map do |(name, url), index|
        item = {
          "@type" => "ListItem",
          "position" => index + 1,
          "name" => name
        }
        item["item"] = url if url.present?
        item
      end
    }
  end

  # Generate Organization Schema
  # @param options [Hash] Organization data (optional, uses defaults from ENV)
  # @option options [String] :name Organization name
  # @option options [String] :url Website URL
  # @option options [String] :logo Logo URL
  # @option options [String] :description Description
  # @option options [String] :email Contact email
  # @option options [Hash] :social Social media URLs
  # @return [Hash] JSON-LD structured data for Organization
  def organization_schema(options = {})
    site_url = ENV.fetch("SITE_URL", "https://example.com")
    site_name = ENV.fetch("SITE_NAME", "宮川 剛 - Portfolio")

    schema = {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => options[:name] || site_name,
      "url" => options[:url] || site_url
    }

    # Logo
    if options[:logo].present?
      schema["logo"] = {
        "@type" => "ImageObject",
        "url" => options[:logo]
      }
    end

    # Description
    schema["description"] = options[:description] if options[:description].present?

    # Contact point
    if options[:email].present?
      schema["contactPoint"] = {
        "@type" => "ContactPoint",
        "contactType" => "customer service",
        "email" => options[:email]
      }
    end

    # Social media
    if options[:social].present?
      same_as = []
      same_as << options[:social][:twitter] if options[:social][:twitter].present?
      same_as << options[:social][:github] if options[:social][:github].present?
      same_as << options[:social][:linkedin] if options[:social][:linkedin].present?
      schema["sameAs"] = same_as if same_as.any?
    end

    schema
  end

  # Generate Person Schema (for author/profile pages)
  # @param options [Hash] Person data
  # @option options [String] :name Person name
  # @option options [String] :url Profile URL
  # @option options [String] :image Profile image URL
  # @option options [String] :job_title Job title
  # @option options [String] :description Bio/description
  # @option options [Hash] :social Social media URLs
  # @return [Hash] JSON-LD structured data for Person
  def person_schema(options = {})
    return nil if options[:name].blank?

    schema = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => options[:name]
    }

    schema["url"] = options[:url] if options[:url].present?
    schema["image"] = options[:image] if options[:image].present?
    schema["jobTitle"] = options[:job_title] if options[:job_title].present?
    schema["description"] = options[:description] if options[:description].present?

    if options[:social].present?
      same_as = []
      same_as << options[:social][:twitter] if options[:social][:twitter].present?
      same_as << options[:social][:github] if options[:social][:github].present?
      same_as << options[:social][:linkedin] if options[:social][:linkedin].present?
      schema["sameAs"] = same_as if same_as.any?
    end

    schema
  end

  # Generate WebSite Schema (for site-wide search)
  # @param options [Hash] Website data
  # @option options [String] :name Site name
  # @option options [String] :url Site URL
  # @option options [String] :search_url Search action URL template
  # @return [Hash] JSON-LD structured data for WebSite
  def website_schema(options = {})
    site_url = ENV.fetch("SITE_URL", "https://example.com")
    site_name = ENV.fetch("SITE_NAME", "宮川 剛 - Portfolio")

    schema = {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => options[:name] || site_name,
      "url" => options[:url] || site_url
    }

    # Search action
    if options[:search_url].present?
      schema["potentialAction"] = {
        "@type" => "SearchAction",
        "target" => {
          "@type" => "EntryPoint",
          "urlTemplate" => options[:search_url]
        },
        "query-input" => "required name=search_term_string"
      }
    end

    schema
  end

  # Convert schema hash to JSON-LD script tag
  # @param schema [Hash, Array<Hash>] Schema data (single or multiple)
  # @return [String] HTML script tag with JSON-LD
  def structured_data_tag(schema)
    return "" if schema.blank?

    schemas = schema.is_a?(Array) ? schema : [ schema ]
    schemas = schemas.compact

    return "" if schemas.empty?

    content = if schemas.size == 1
                schemas.first.to_json
    else
                schemas.to_json
    end

    content_tag(:script, content.html_safe, type: "application/ld+json")
  end

  # Generate multiple schemas and combine into a single script tag
  # @param schemas [Array<Hash>] Array of schema hashes
  # @return [String] HTML script tag with combined JSON-LD
  def combined_structured_data_tag(*schemas)
    valid_schemas = schemas.flatten.compact
    return "" if valid_schemas.empty?

    if valid_schemas.size == 1
      structured_data_tag(valid_schemas.first)
    else
      content_tag(:script, valid_schemas.to_json.html_safe, type: "application/ld+json")
    end
  end
end
