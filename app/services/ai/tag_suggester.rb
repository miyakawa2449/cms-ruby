# Suggests tags for articles based on content analysis
# Matches with existing tags and proposes new ones
module Ai
  class TagSuggester < BaseGenerator
    DEFAULT_MAX_TAGS = 6

    # Suggest tags for the article
    # @param max_tags [Integer] Maximum number of tags to suggest
    # @param include_existing [Boolean] Include existing system tags
    # @return [Hash] { success: Boolean, data: { suggested_tags: Array } }
    def suggest(max_tags: DEFAULT_MAX_TAGS, include_existing: true)
      begin
        validate_article!

        generation = create_generation_record(article.content)
        existing_tags = include_existing ? Tag.pluck(:name) : []
        prompt = build_prompt(max_tags, existing_tags)
        response = bedrock_client.invoke_model(model_id, prompt)

        tags = parse_tags(response[:content], existing_tags)
        complete_generation!(generation, { tags: tags }, response[:usage])

        build_result(
          data: { suggested_tags: tags },
          generation: generation,
          usage: response[:usage]
        )
      rescue Ai::Error => e
        fail_generation!(generation, e) if generation.present?
        build_error_result(e.message)
      rescue => e
        Rails.logger.error("Tag suggestion failed: #{e.message}")
        fail_generation!(generation, e) if generation.present?
        build_error_result("予期せぬエラーが発生しました: #{e.message}")
      end
    end

    protected

    def generation_type
      :tags
    end

    private

    def validate_article!
      raise Ai::ValidationError.new("Article is required", field: :article) if article.blank?
      raise Ai::ValidationError.new("Article content is required", field: :content) if article.content.blank?
    end

    def build_prompt(max_tags, existing_tags)
      existing_tags_list = existing_tags.any? ? existing_tags.join(", ") : "なし"

      <<~PROMPT
        以下の記事に適切なタグを#{max_tags}個まで提案してください。

        記事タイトル: #{article.title}

        記事本文:
        #{article.content.truncate(5000)}

        システムに存在する既存タグ:
        #{existing_tags_list}

        要件:
        - 記事の内容を的確に表すタグを選択
        - 既存タグとのマッチングを優先
        - 新規タグも提案可能（既存にない場合）
        - 各タグの関連度（confidence）を0-1で評価
        - タグは具体的で検索しやすいもの
        - 日本語タグを優先

        出力形式（JSON）:
        {
          "tags": [
            {"name": "タグ名", "confidence": 0.98, "existing": true},
            {"name": "タグ名", "confidence": 0.85, "existing": false}
          ]
        }

        JSONのみを出力してください。
      PROMPT
    end

    def parse_tags(content, existing_tags)
      json = parse_json_response(content)
      tags = json["tags"] || []

      existing_tags_map = Tag.where(name: existing_tags).index_by(&:name)

      tags.map do |tag|
        existing_tag = existing_tags_map[tag["name"]]
        {
          name: tag["name"],
          confidence: tag["confidence"].to_f,
          existing: existing_tag.present?,
          tag_id: existing_tag&.id
        }
      end.sort_by { |t| -t[:confidence] }
    rescue => e
      Rails.logger.warn("Failed to parse tags: #{e.message}")
      []
    end
  end
end
