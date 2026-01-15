# Generates SEO metadata for articles
# Creates meta descriptions, keywords, OG tags, etc.
module Ai
  class SeoMetaGenerator < BaseGenerator
    AVAILABLE_FIELDS = %w[
      meta_description
      meta_keywords
      og_title
      og_description
    ].freeze

    # Generate SEO metadata for the article
    # @param fields [Array] Fields to generate (defaults to all)
    # @return [Hash] { success: Boolean, data: { meta_description: String, ... } }
    def generate(fields: AVAILABLE_FIELDS)
      begin
        validate_article!
        validate_fields!(fields)

        generation = create_generation_record(article.content)
        prompt = build_prompt(fields)
        response = bedrock_client.invoke_model(model_id, prompt)

        meta_data = parse_meta_data(response[:content], fields)
        complete_generation!(generation, meta_data, response[:usage])

        build_result(
          data: meta_data,
          generation: generation,
          usage: response[:usage]
        )
      rescue Ai::Error => e
        fail_generation!(generation, e) if generation.present?
        build_error_result(e.message)
      rescue => e
        Rails.logger.error("SEO meta generation failed: #{e.message}")
        fail_generation!(generation, e) if generation.present?
        build_error_result("予期せぬエラーが発生しました: #{e.message}")
      end
    end

    protected

    def generation_type
      :seo_meta
    end

    private

    def validate_article!
      raise Ai::ValidationError.new("Article is required", field: :article) if article.blank?
      raise Ai::ValidationError.new("Article content is required", field: :content) if article.content.blank?
    end

    def validate_fields!(fields)
      invalid_fields = fields - AVAILABLE_FIELDS
      if invalid_fields.any?
        raise Ai::ValidationError.new("Invalid fields: #{invalid_fields.join(', ')}", field: :fields)
      end
    end

    def build_prompt(fields)
      fields_description = build_fields_description(fields)

      <<~PROMPT
        以下の記事のSEOメタデータを生成してください。

        記事タイトル: #{article.title}

        記事本文:
        #{article.content.truncate(5000)}

        生成するフィールド:
        #{fields_description}

        要件:
        - メタディスクリプション: 160文字以内、記事の要点を含む
        - メタキーワード: 5-10個、カンマ区切り
        - OGタイトル: 60文字以内、タイトルを最適化
        - OGディスクリプション: 200文字以内、SNS向けの魅力的な説明

        出力形式（JSON）:
        {
          "meta_description": "説明文",
          "meta_keywords": "キーワード1, キーワード2",
          "og_title": "OGタイトル",
          "og_description": "OG説明文"
        }

        JSONのみを出力してください。
      PROMPT
    end

    def build_fields_description(fields)
      descriptions = {
        "meta_description" => "メタディスクリプション（160文字以内）",
        "meta_keywords" => "メタキーワード（カンマ区切り）",
        "og_title" => "OGタイトル（60文字以内）",
        "og_description" => "OGディスクリプション（200文字以内）"
      }

      fields.map { |f| "- #{descriptions[f]}" }.join("\n")
    end

    def parse_meta_data(content, fields)
      json = parse_json_response(content)

      result = {}
      fields.each do |field|
        value = json[field]
        result[field] = sanitize_meta_value(field, value) if value.present?
      end

      result
    rescue => e
      Rails.logger.warn("Failed to parse SEO meta: #{e.message}")
      {}
    end

    def sanitize_meta_value(field, value)
      case field
      when "meta_description"
        value.to_s.truncate(160)
      when "og_title"
        value.to_s.truncate(60)
      when "og_description"
        value.to_s.truncate(200)
      else
        value.to_s
      end
    end
  end
end
