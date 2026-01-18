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
      content_preview = article.content.truncate(4000)

      <<~PROMPT
        あなたは技術ブログのコンテンツ分類の専門家です。
        以下の記事を分析し、最適なタグを#{max_tags}個まで提案してください。

        【記事タイトル】
        #{article.title}

        【記事本文】
        #{content_preview}

        【既存のタグ一覧】
        #{existing_tags_list}

        【タグ選定の基準】
        1. **技術キーワード**: 使用されているプログラミング言語、フレームワーク、ツール
        2. **トピック分類**: 記事の主題（パフォーマンス、セキュリティ、テスト等）
        3. **レベル**: 初心者向け、中級者向け、上級者向け（該当する場合）
        4. **カテゴリ**: チュートリアル、解説、Tips、トラブルシューティング等

        【要件】
        - 既存タグとの完全一致を最優先（表記揺れを避ける）
        - 一般的すぎるタグは避ける（例：「プログラミング」より「Ruby」）
        - 各タグの関連度（confidence）を0.0〜1.0で評価
        - 日本語タグを基本とするが、技術用語は英語可
        - SEO効果の高い具体的なタグを選択

        【出力形式】
        以下のJSON形式で出力してください：
        {
          "tags": [
            {"name": "タグ名", "confidence": 0.98, "existing": true},
            {"name": "新規タグ名", "confidence": 0.85, "existing": false}
          ]
        }

        注意：
        - JSONのみを出力し、説明文は含めないでください
        - confidenceが高い順に並べてください
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
