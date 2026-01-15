# Custom error classes for AI services
# Zeitwerk expects Ai::Errors from errors.rb
module Ai
  # Errors namespace for Zeitwerk compatibility
  module Errors
  end

  # Base error class for all AI-related errors
  class Error < StandardError; end

  # Raised when Amazon Bedrock API call fails
  class BedrockError < Error
    attr_reader :original_error, :error_type

    def initialize(message, original_error: nil, error_type: :unknown)
      @original_error = original_error
      @error_type = error_type
      super(message)
    end
  end

  # Raised when API rate limit is exceeded
  class RateLimitError < BedrockError
    def initialize(message = "API rate limit exceeded")
      super(message, error_type: :rate_limit)
    end
  end

  # Raised when request times out
  class TimeoutError < BedrockError
    def initialize(message = "Request timed out")
      super(message, error_type: :timeout)
    end
  end

  # Raised when model is unavailable
  class ModelUnavailableError < BedrockError
    def initialize(message = "Model is unavailable")
      super(message, error_type: :model_unavailable)
    end
  end

  # Raised when input validation fails
  class ValidationError < Error
    attr_reader :field

    def initialize(message, field: nil)
      @field = field
      super(message)
    end
  end

  # Raised when configuration is missing or invalid
  class ConfigurationError < Error; end
end
