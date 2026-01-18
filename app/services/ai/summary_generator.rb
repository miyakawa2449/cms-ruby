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
      content_preview = article.content.truncate(4000)

      <<~PROMPT
        あなたは経験豊富なテクニカルライターです。
        以下の技術記事を分析し、#{count}つの異なる視点から要約を作成してください。

        【記事タイトル】
        #{article.title}

        【記事本文】
        #{content_preview}

        【タスク】
        #{max_chars}文字以内の要約を#{count}つ作成してください。
        それぞれ異なるアプローチで記事の価値を伝えてください：

        1. **内容中心型**: 記事で解説されている技術・手法の本質を簡潔に説明
        2. **課題解決型**: 読者が得られるメリット・解決できる課題を強調
        3. **学習誘導型**: 記事を読むことで学べる具体的なスキルを提示

        【要件】
        - 各要約は必ず#{max_chars}文字以内
        - 技術的に正確な表現を使用
        - 読者の興味を引く導入にする
        - 記事の核心的な価値を伝える
        - 自然で読みやすい日本語

        【出力形式】
        以下のJSON形式で出力してください：
        {
          "summaries": [
            {"text": "要約1", "length": 文字数},
            {"text": "要約2", "length": 文字数},
            {"text": "要約3", "length": 文字数}
          ]
        }

        注意：JSONのみを出力し、説明文は含めないでください。
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
