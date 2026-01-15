# Generates SEO-friendly URL slugs for articles
# Converts Japanese titles to English slugs
module Ai
  class SlugGenerator < BaseGenerator
    DEFAULT_COUNT = 3

    # Generate slug candidates for the article
    # @param title [String] Article title (defaults to article.title)
    # @param count [Integer] Number of slug candidates to generate
    # @return [Hash] { success: Boolean, data: { slugs: Array } }
    def generate(title: nil, count: DEFAULT_COUNT)
      begin
        target_title = title || article&.title
        validate_title!(target_title)

        input_content = target_title
        generation = create_generation_record(input_content)
        prompt = build_prompt(target_title, count)
        response = bedrock_client.invoke_model(model_id, prompt)

        slugs = parse_slugs(response[:content])
        complete_generation!(generation, { slugs: slugs }, response[:usage])

        build_result(
          data: { slugs: slugs },
          generation: generation,
          usage: response[:usage]
        )
      rescue Ai::Error => e
        fail_generation!(generation, e) if generation.present?
        build_error_result(e.message)
      rescue => e
        Rails.logger.error("Slug generation failed: #{e.message}")
        fail_generation!(generation, e) if generation.present?
        build_error_result("予期せぬエラーが発生しました: #{e.message}")
      end
    end

    protected

    def generation_type
      :slug
    end

    private

    def validate_title!(title)
      raise Ai::ValidationError.new("Title is required", field: :title) if title.blank?
    end

    def build_prompt(title, count)
      <<~PROMPT
        以下のタイトルからSEOに最適化されたURLスラッグを#{count}つ生成してください。

        タイトル: #{title}

        要件:
        - 英語のスラッグを生成（日本語タイトルの場合は適切に翻訳）
        - 小文字のみ使用
        - 単語はハイフンで区切る
        - 50文字以内
        - SEOキーワードを含める
        - 読みやすく覚えやすいもの
        - 各スラッグのSEOスコア（0-100）を評価

        出力形式（JSON）:
        {
          "slugs": [
            {"slug": "slug-example", "seo_score": 95},
            {"slug": "another-slug", "seo_score": 88}
          ]
        }

        JSONのみを出力してください。
      PROMPT
    end

    def parse_slugs(content)
      json = parse_json_response(content)
      slugs = json["slugs"] || []

      slugs.map do |slug|
        normalized_slug = normalize_slug(slug["slug"] || "")
        {
          slug: normalized_slug,
          available: slug_available?(normalized_slug),
          seo_score: slug["seo_score"].to_i
        }
      end.sort_by { |s| -s[:seo_score] }
    rescue => e
      Rails.logger.warn("Failed to parse slugs: #{e.message}")
      []
    end

    def normalize_slug(slug)
      slug.downcase
          .gsub(/[^a-z0-9\-]/, "-")  # Replace non-alphanumeric with hyphen
          .gsub(/-+/, "-")            # Remove consecutive hyphens
          .gsub(/^-|-$/, "")          # Remove leading/trailing hyphens
          .truncate(50, omission: "")
    end

    def slug_available?(slug)
      return true if slug.blank?

      # Check if slug is already taken by another article
      existing = Article.where(slug: slug)
      existing = existing.where.not(id: article.id) if article.present?
      existing.none?
    end
  end
end
