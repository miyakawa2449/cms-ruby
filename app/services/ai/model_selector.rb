# Model selection service for Amazon Bedrock AI features
# Selects appropriate AI model based on generation type for optimal quality/speed/cost balance
module Ai
  class ModelSelector
    # Model configurations with cost per 1M tokens (USD)
    # Updated to Claude 4.5 models with cross-region inference profiles (us. prefix required)
    # Sonnet 4.5: Higher quality, best for complex tasks ($3/$15 per 1M tokens)
    # Haiku 4.5: Faster, cheaper, good for simple tasks ($1/$5 per 1M tokens)
    MODELS = {
      summary: "us.anthropic.claude-sonnet-4-5-20250929-v1:0",    # High quality summaries
      title: "us.anthropic.claude-sonnet-4-5-20250929-v1:0",      # High quality title suggestions
      tags: "us.anthropic.claude-haiku-4-5-20251001-v1:0",        # Fast tag extraction
      slug: "us.anthropic.claude-haiku-4-5-20251001-v1:0",        # Fast slug generation
      seo_meta: "us.anthropic.claude-sonnet-4-5-20250929-v1:0",   # High quality SEO text
      structure: "us.anthropic.claude-sonnet-4-5-20250929-v1:0"   # Complex structure suggestions
    }.freeze

    # Cost per 1M tokens (input/output)
    MODEL_COSTS = {
      # Claude 4.5 models (current)
      "us.anthropic.claude-sonnet-4-5-20250929-v1:0" => { input: 3.0, output: 15.0 },
      "us.anthropic.claude-haiku-4-5-20251001-v1:0" => { input: 1.0, output: 5.0 },
      # Claude 3.5/3 models (kept for backward compatibility with existing records)
      "us.anthropic.claude-3-5-sonnet-20241022-v2:0" => { input: 3.0, output: 15.0 },
      "us.anthropic.claude-3-haiku-20240307-v1:0" => { input: 0.25, output: 1.25 },
      "anthropic.claude-3-5-sonnet-20241022-v2:0" => { input: 3.0, output: 15.0 },
      "anthropic.claude-3-haiku-20240307-v1:0" => { input: 0.25, output: 1.25 }
    }.freeze

    # Select model for given generation type
    def self.select(generation_type)
      MODELS[generation_type.to_sym] || MODELS[:summary]
    end

    # Calculate cost for token usage
    def self.calculate_cost(model_id, input_tokens, output_tokens)
      costs = MODEL_COSTS[model_id] || { input: 0, output: 0 }
      ((input_tokens * costs[:input] + output_tokens * costs[:output]) / 1_000_000.0).round(6)
    end

    # Get model display name
    def self.display_name(model_id)
      case model_id
      # Claude 4.5 models (current)
      when /claude-sonnet-4-5-20250929/
        "Claude Sonnet 4.5"
      when /claude-haiku-4-5-20251001/
        "Claude Haiku 4.5"
      # Claude 4 models
      when /claude-sonnet-4-20250514/
        "Claude Sonnet 4"
      # Claude 3.5/3 models (backward compatibility)
      when /claude-3-5-sonnet/
        "Claude 3.5 Sonnet"
      when /claude-3-haiku/
        "Claude 3 Haiku"
      else
        model_id
      end
    end

    # Check if model is available
    def self.available?(model_id)
      MODEL_COSTS.key?(model_id)
    end
  end
end
