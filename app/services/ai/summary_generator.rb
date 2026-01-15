# Generates article summaries using AI
# Creates excerpt/description text for articles
module Ai
  class SummaryGenerator < BaseGenerator
    LENGTH_CONFIGS = {
      "short" => { max_chars: 80, description: "短い版" },
      "medium" => { max_chars: 120, description: "中版" },
      "long" => { max_chars: 160, description: "長い版" }
    }.freeze

    DEFAULT_COUNT = 3

    # Generate summaries for the article
    # @param length [String] 'short', 'medium', or 'long'
    # @param count [Integer] Number of summaries to generate
    # @return [Hash] { success: Boolean, data: { summaries: Array } }
    def generate(length: "medium", count: DEFAULT_COUNT)
      begin
        validate_article!
        validate_length!(length)

        generation = create_generation_record(article.content)
        prompt = build_prompt(length, count)
        response = bedrock_client.invoke_model(model_id, prompt)

        summaries = parse_summaries(response[:content], length)
        complete_generation!(generation, { summaries: summaries }, response[:usage])

        build_result(
          data: { summaries: summaries },
          generation: generation,
          usage: response[:usage]
        )
      rescue Ai::Error => e
        fail_generation!(generation, e) if generation.present?
        build_error_result(e.message)
      rescue => e
        Rails.logger.error("Summary generation failed: #{e.message}")
        fail_generation!(generation, e) if generation.present?
        build_error_result("予期せぬエラーが発生しました: #{e.message}")
      end
    end

    protected

    def generation_type
      :summary
    end

    private

    def validate_article!
      raise Ai::ValidationError.new("Article is required", field: :article) if article.blank?
      raise Ai::ValidationError.new("Article content is required", field: :content) if article.content.blank?
    end

    def validate_length!(length)
      unless LENGTH_CONFIGS.key?(length)
        raise Ai::ValidationError.new("Invalid length: #{length}", field: :length)
      end
    end

    def build_prompt(length, count)
      max_chars = LENGTH_CONFIGS[length][:max_chars]

      <<~PROMPT
        以下の記事の要約を#{max_chars}文字以内で#{count}つ生成してください。

        記事タイトル: #{article.title}

        記事本文:
        #{article.content.truncate(5000)}

        要件:
        - 記事の主要なポイントを簡潔にまとめる
        - #{max_chars}文字以内に収める
        - 読者の興味を引く表現を使う
        - #{count}つの異なる視点から要約を作成
        - SEOを意識した自然な文章

        出力形式（JSON）:
        {
          "summaries": [
            {"text": "要約1", "length": 文字数},
            {"text": "要約2", "length": 文字数},
            {"text": "要約3", "length": 文字数}
          ]
        }

        JSONのみを出力してください。
      PROMPT
    end

    def parse_summaries(content, length)
      json = parse_json_response(content)
      summaries = json["summaries"] || []

      summaries.map.with_index do |summary, index|
        {
          text: summary["text"] || "",
          length: (summary["text"] || "").length,
          type: length
        }
      end
    rescue => e
      Rails.logger.warn("Failed to parse summaries: #{e.message}")
      []
    end
  end
end
