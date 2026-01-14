# Base class for AI content generators
# Provides common functionality for all AI generation services
require_relative 'errors'

module Ai
  class BaseGenerator
    attr_reader :article, :admin_user

    def initialize(article: nil, admin_user: nil)
      @article = article
      @admin_user = admin_user
      @bedrock_client = BedrockClient.new
    end

    protected

    def bedrock_client
      @bedrock_client
    end

    # Get model for this generation type
    def model_id
      ModelSelector.select(generation_type)
    end

    # Override in subclasses
    def generation_type
      raise NotImplementedError, 'Subclass must implement generation_type'
    end

    # Create an AiGeneration record to track this generation
    def create_generation_record(input_content)
      AiGeneration.create!(
        article: article,
        admin_user: admin_user,
        generation_type: generation_type.to_s,
        input_content: input_content,
        model_used: model_id,
        status: 'pending'
      )
    end

    # Complete the generation record with results
    def complete_generation!(generation, output_data, usage)
      input_tokens = usage[:input_tokens] || 0
      output_tokens = usage[:output_tokens] || 0
      cost = ModelSelector.calculate_cost(model_id, input_tokens, output_tokens)

      generation.complete!(
        output_data,
        tokens: input_tokens + output_tokens,
        cost: cost
      )

      # Track usage statistics
      UsageTracker.track(
        model_id: model_id,
        generation_type: generation_type,
        tokens: input_tokens + output_tokens,
        cost: cost
      )
    end

    # Mark generation as failed
    def fail_generation!(generation, error)
      generation.fail!(error.message)
    end

    # Parse JSON from AI response
    def parse_json_response(content)
      # Try to extract JSON from the response
      json_match = content.match(/\{[\s\S]*\}/)
      return {} unless json_match

      JSON.parse(json_match[0])
    rescue JSON::ParserError => e
      Rails.logger.warn("Failed to parse AI JSON response: #{e.message}")
      {}
    end

    # Build result hash with standard format
    def build_result(data:, generation:, usage:)
      {
        success: true,
        data: data.merge(
          generation_id: generation.id,
          tokens_used: generation.tokens_used,
          cost: generation.cost
        )
      }
    end

    # Build error result hash
    def build_error_result(message)
      { success: false, error: message }
    end
  end
end
