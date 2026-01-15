# Suggests article structure based on topic/theme
# Provides outline with headings and section descriptions
module Ai
  class StructureSuggester < BaseGenerator
    # Suggest article structure based on a topic
    # @param topic [String] Article topic or theme
    # @param detail_level [String] 'basic', 'detailed', or 'comprehensive'
    # @return [Hash] { success: Boolean, data: { structure: Hash } }
    def suggest(topic:, detail_level: "detailed")
      begin
        validate_topic!(topic)
        validate_detail_level!(detail_level)

        generation = create_generation_record(topic)
        prompt = build_prompt(topic, detail_level)
        response = bedrock_client.invoke_model(model_id, prompt)

        structure = parse_structure(response[:content])
        complete_generation!(generation, { structure: structure }, response[:usage])

        build_result(
          data: { structure: structure },
          generation: generation,
          usage: response[:usage]
        )
      rescue Ai::Error => e
        fail_generation!(generation, e) if generation.present?
        build_error_result(e.message)
      rescue => e
        Rails.logger.error("Structure suggestion failed: #{e.message}")
        fail_generation!(generation, e) if generation.present?
        build_error_result("予期せぬエラーが発生しました: #{e.message}")
      end
    end

    protected

    def generation_type
      :structure
    end

    private

    def validate_topic!(topic)
      raise Ai::ValidationError.new("Topic is required", field: :topic) if topic.blank?
    end

    def validate_detail_level!(level)
      valid_levels = %w[basic detailed comprehensive]
      unless valid_levels.include?(level)
        raise Ai::ValidationError.new("Invalid detail level: #{level}", field: :detail_level)
      end
    end

    def build_prompt(topic, detail_level)
      section_count = case detail_level
      when "basic" then "3-4"
      when "detailed" then "5-7"
      when "comprehensive" then "8-10"
      end

      <<~PROMPT
        以下のトピックについて、技術ブログ記事の構成案を作成してください。

        トピック: #{topic}
        詳細度: #{detail_level}（#{section_count}セクション程度）

        要件:
        - 論理的で読みやすい構成
        - 各セクションに適切な見出し（H2/H3）
        - 各セクションの簡単な説明文
        - 推奨文字数（合計と各セクション）
        - 関連トピックの提案

        出力形式（JSON）:
        {
          "title_suggestions": ["タイトル案1", "タイトル案2"],
          "sections": [
            {
              "heading": "セクション見出し",
              "level": 2,
              "description": "このセクションの内容説明",
              "recommended_words": 300,
              "subsections": [
                {
                  "heading": "サブセクション見出し",
                  "level": 3,
                  "description": "内容説明",
                  "recommended_words": 150
                }
              ]
            }
          ],
          "total_recommended_words": 2000,
          "related_topics": ["関連トピック1", "関連トピック2"],
          "keywords": ["キーワード1", "キーワード2"]
        }

        JSONのみを出力してください。
      PROMPT
    end

    def parse_structure(content)
      json = parse_json_response(content)

      {
        title_suggestions: json["title_suggestions"] || [],
        sections: parse_sections(json["sections"] || []),
        total_recommended_words: json["total_recommended_words"].to_i,
        related_topics: json["related_topics"] || [],
        keywords: json["keywords"] || []
      }
    rescue => e
      Rails.logger.warn("Failed to parse structure: #{e.message}")
      {}
    end

    def parse_sections(sections)
      sections.map do |section|
        {
          heading: section["heading"],
          level: section["level"].to_i,
          description: section["description"],
          recommended_words: section["recommended_words"].to_i,
          subsections: parse_sections(section["subsections"] || [])
        }
      end
    end
  end
end
