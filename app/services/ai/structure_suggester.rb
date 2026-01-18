# Suggests article structure based on topic/theme
# Provides outline with headings and section descriptions
module Ai
  class StructureSuggester < BaseGenerator
    # Suggest article structure based on a topic
    # @param topic [String] Article topic or theme
    # @param detail_level [String] 'basic', 'detailed', or 'comprehensive'
    # @param format [String] 'json' or 'markdown'
    # @return [Hash] { success: Boolean, data: { structure: Hash/String } }
    def suggest(topic:, detail_level: "detailed", format: "markdown")
      begin
        validate_topic!(topic)
        validate_detail_level!(detail_level)
        validate_format!(format)

        generation = create_generation_record(topic)
        prompt = format == "markdown" ? build_markdown_prompt(topic, detail_level) : build_json_prompt(topic, detail_level)
        response = bedrock_client.invoke_model(model_id, prompt)

        structure = format == "markdown" ? response[:content].strip : parse_structure(response[:content])
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
      raise Ai::ValidationError.new("トピックを入力してください", field: :topic) if topic.blank?
    end

    def validate_detail_level!(level)
      valid_levels = %w[basic detailed comprehensive]
      unless valid_levels.include?(level)
        raise Ai::ValidationError.new("無効な詳細レベルです: #{level}", field: :detail_level)
      end
    end

    def validate_format!(format)
      valid_formats = %w[json markdown]
      unless valid_formats.include?(format)
        raise Ai::ValidationError.new("無効な出力形式です: #{format}", field: :format)
      end
    end

    def build_markdown_prompt(topic, detail_level)
      section_count = section_count_for(detail_level)

      <<~PROMPT
        あなたはプロの技術ライターです。以下のトピックについて、技術ブログ記事の構成（アウトライン）を作成してください。

        【トピック】
        #{topic}

        【要件】
        - #{section_count}程度のセクション構成
        - 論理的で読みやすい流れ
        - 読者が理解しやすい順序
        - 実践的な内容を含む

        【出力形式】
        Markdown形式の見出し構成のみを出力してください。
        - H2（##）を主要セクション
        - H3（###）をサブセクション
        - 各見出しの下に1行の簡単な説明（コメントとして）

        【出力例】
        ## はじめに
        <!-- この記事の目的と対象読者について説明 -->

        ## 基本概念
        <!-- 主要な概念や用語の解説 -->

        ### 重要な用語
        <!-- 理解に必要な専門用語の説明 -->

        ## 実装方法
        <!-- 具体的な実装手順を解説 -->

        ## まとめ
        <!-- 記事の要点と次のステップ -->

        【注意事項】
        - 必ず日本語で回答してください
        - Markdown形式の見出しとコメントのみを出力してください
        - 説明文は不要です
      PROMPT
    end

    def build_json_prompt(topic, detail_level)
      section_count = section_count_for(detail_level)

      <<~PROMPT
        あなたはプロの技術ライターです。以下のトピックについて、技術ブログ記事の構成案を作成してください。

        【トピック】
        #{topic}

        【詳細度】
        #{detail_level}（#{section_count}程度）

        【要件】
        - 論理的で読みやすい構成
        - 各セクションに適切な見出し（H2/H3）
        - 各セクションの簡単な説明文
        - 推奨文字数（合計と各セクション）
        - 関連トピックの提案

        【出力形式】
        以下のJSON形式で出力してください：
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

        【注意事項】
        - 必ず日本語で回答してください
        - JSONのみを出力してください（説明文は不要）
      PROMPT
    end

    def section_count_for(detail_level)
      case detail_level
      when "basic" then "3〜4セクション"
      when "detailed" then "5〜7セクション"
      when "comprehensive" then "8〜10セクション"
      end
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
