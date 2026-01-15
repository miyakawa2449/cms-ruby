# frozen_string_literal: true

module Ai
  # AI-powered title suggestion service
  # Generates two types of titles:
  # 1. Clear and descriptive titles based on content
  # 2. Engaging, clickable titles optimized for social media
  class TitleSuggester < BaseGenerator
    DEFAULT_COUNT = 3

    # Generate title suggestions
    # @param count [Integer] Number of suggestions per type (default: 3)
    # @return [Hash] Result with descriptive and engaging titles
    def suggest(count: DEFAULT_COUNT)
      validate_article!

      generation = create_generation_record(article.content)
      prompt = build_prompt(count)
      response = bedrock_client.invoke_model(model_id, prompt)

      titles_data = parse_titles(response[:content])
      complete_generation!(generation, titles_data, response[:usage])

      build_result(
        data: {
          descriptive_titles: titles_data[:descriptive_titles],
          engaging_titles: titles_data[:engaging_titles],
          current_title: article.title
        },
        generation: generation,
        usage: response[:usage]
      )
    rescue Ai::Error => e
      fail_generation!(generation, e) if generation.present?
      build_error_result(e.message)
    rescue => e
      Rails.logger.error("Title suggestion failed: #{e.message}")
      fail_generation!(generation, e) if generation.present?
      build_error_result("タイトル提案に失敗しました: #{e.message}")
    end

    protected

    def generation_type
      :title
    end

    private

    def validate_article!
      raise Ai::ValidationError.new('記事が必要です', field: :article) if article.blank?
      raise Ai::ValidationError.new('記事の本文が必要です', field: :content) if article.content.blank?
    end

    def build_prompt(count)
      content_preview = article.content.truncate(2000)
      existing_title = article.title.presence || "（未設定）"

      <<~PROMPT
        あなたは経験豊富なコンテンツマーケティングの専門家です。
        以下の記事本文を分析して、2種類のタイトルを提案してください。

        【現在のタイトル】
        #{existing_title}

        【記事本文】
        #{content_preview}

        【タスク】
        以下の2種類のタイトルを、それぞれ#{count}個ずつ提案してください：

        1. **わかりやすいタイトル（Descriptive）**
           - 記事の内容を正確に表現
           - 読者が内容を理解しやすい
           - 検索エンジンに最適化
           - 30〜50文字程度

        2. **SNS映えするタイトル（Engaging）**
           - クリックされやすい魅力的な表現
           - 好奇心を刺激する
           - 感情に訴える
           - 数字や具体例を含む
           - 25〜40文字程度

        【出力形式】
        以下のJSON形式で出力してください：
        {
          "descriptive_titles": [
            {"title": "タイトル1", "reason": "選定理由"},
            {"title": "タイトル2", "reason": "選定理由"}
          ],
          "engaging_titles": [
            {"title": "タイトル1", "reason": "選定理由"},
            {"title": "タイトル2", "reason": "選定理由"}
          ]
        }

        注意：
        - JSONのみを出力し、説明文は含めないでください
        - タイトルは日本語で提案してください
        - 既存のタイトルがある場合は、それを改善する形で提案してください
      PROMPT
    end

    def parse_titles(content)
      json = parse_json_response(content)

      {
        descriptive_titles: normalize_titles(json["descriptive_titles"]),
        engaging_titles: normalize_titles(json["engaging_titles"])
      }
    rescue => e
      Rails.logger.warn("Failed to parse titles: #{e.message}")
      { descriptive_titles: [], engaging_titles: [] }
    end

    def normalize_titles(titles)
      return [] if titles.blank?

      titles.map do |item|
        {
          title: item["title"],
          reason: item["reason"]
        }
      end
    end
  end
end
