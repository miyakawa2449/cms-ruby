# Amazon Bedrock API client for AI model invocation
# Handles communication with AWS Bedrock Runtime service
require "aws-sdk-bedrockruntime"

module Ai
  class BedrockClient
    DEFAULT_MAX_TOKENS = 2000
    DEFAULT_TEMPERATURE = 0.7
    REQUEST_TIMEOUT = 30 # seconds

    def initialize
      @client = build_client
    end

    # Invoke a model with given prompt
    # @param model_id [String] Bedrock model ID
    # @param prompt [String] User prompt
    # @param max_tokens [Integer] Maximum tokens in response
    # @param temperature [Float] Temperature for generation (0-1)
    # @return [Hash] { content: String, usage: { input_tokens: Integer, output_tokens: Integer } }
    def invoke_model(model_id, prompt, max_tokens: DEFAULT_MAX_TOKENS, temperature: DEFAULT_TEMPERATURE)
      validate_inputs!(model_id, prompt)

      request_body = build_request_body(prompt, max_tokens, temperature)

      response = @client.invoke_model({
        model_id: model_id,
        body: request_body.to_json,
        content_type: "application/json",
        accept: "application/json"
      })

      parse_response(response)
    rescue Aws::BedrockRuntime::Errors::ThrottlingException => e
      handle_throttling_error(e)
    rescue Aws::BedrockRuntime::Errors::ServiceUnavailableException => e
      handle_unavailable_error(e)
    rescue Aws::BedrockRuntime::Errors::ModelTimeoutException => e
      handle_timeout_error(e)
    rescue Aws::BedrockRuntime::Errors::ServiceError => e
      handle_service_error(e)
    rescue Aws::Errors::ServiceError => e
      handle_aws_error(e)
    end

    # Invoke model with retry logic for transient errors
    # @param model_id [String] Bedrock model ID
    # @param prompt [String] User prompt
    # @param max_retries [Integer] Maximum number of retry attempts (default: 3)
    # @param base_delay [Float] Base delay in seconds for exponential backoff (default: 1.0)
    # @param options [Hash] Additional options passed to invoke_model
    # @return [Hash] { content: String, usage: { input_tokens: Integer, output_tokens: Integer } }
    def invoke_model_with_retry(model_id, prompt, max_retries: 3, base_delay: 1.0, **options)
      retries = 0
      last_error = nil

      begin
        invoke_model(model_id, prompt, **options)
      rescue RateLimitError, TimeoutError, ModelUnavailableError => e
        last_error = e
        retries += 1

        if retries <= max_retries
          # Exponential backoff with jitter to avoid thundering herd
          sleep_time = (base_delay * (2**retries)) + rand(0.0..0.5)
          Rails.logger.warn(
            "AI request retry #{retries}/#{max_retries} after #{sleep_time.round(2)}s " \
            "(#{e.class.name}: #{e.message})"
          )
          sleep(sleep_time)
          retry
        end

        Rails.logger.error("AI request failed after #{max_retries} retries: #{e.message}")
        raise
      end
    end

    # Check if Bedrock service is available
    def available?
      @client.present?
    rescue => e
      Rails.logger.error("Bedrock availability check failed: #{e.message}")
      false
    end

    private

    def build_client
      # Prefer Bedrock-specific credentials, fallback to general AWS credentials
      access_key = ENV["AWS_BEDROCK_ACCESS_KEY_ID"] || ENV["AWS_ACCESS_KEY_ID"]
      secret_key = ENV["AWS_BEDROCK_SECRET_ACCESS_KEY"] || ENV["AWS_SECRET_ACCESS_KEY"]
      region = ENV["AWS_BEDROCK_REGION"] || ENV["AWS_REGION"] || "us-east-1"

      # Use explicit credentials if provided (works on Lightsail and other environments)
      # Fall back to IAM instance profile if no credentials are set (EC2 with IAM role)
      credentials = if access_key.present? && secret_key.present?
                      Aws::Credentials.new(access_key, secret_key)
      else
                      Aws::InstanceProfileCredentials.new
      end

      Aws::BedrockRuntime::Client.new(
        region: region,
        credentials: credentials,
        http_read_timeout: REQUEST_TIMEOUT,
        ssl_verify_peer: !Rails.env.development? # 開発環境ではSSL検証を無効化
      )
    rescue => e
      Rails.logger.error("Failed to build Bedrock client: #{e.message}")
      nil
    end

    def build_request_body(prompt, max_tokens, temperature)
      {
        anthropic_version: "bedrock-2023-05-31",
        max_tokens: max_tokens,
        temperature: temperature,
        messages: [
          {
            role: "user",
            content: prompt
          }
        ]
      }
    end

    def validate_inputs!(model_id, prompt)
      raise Ai::ValidationError.new("Model ID is required", field: :model_id) if model_id.blank?
      raise Ai::ValidationError.new("Prompt is required", field: :prompt) if prompt.blank?
      raise Ai::ValidationError.new("Prompt is too long (max 100,000 chars)", field: :prompt) if prompt.length > 100_000
    end

    def parse_response(response)
      body = JSON.parse(response.body.read)

      {
        content: extract_content(body),
        usage: {
          input_tokens: body.dig("usage", "input_tokens") || 0,
          output_tokens: body.dig("usage", "output_tokens") || 0
        }
      }
    end

    def extract_content(body)
      content = body["content"]
      return "" if content.blank?

      # Claude returns content as array of content blocks
      if content.is_a?(Array)
        content.map { |c| c["text"] }.compact.join("\n")
      else
        content.to_s
      end
    end

    def handle_throttling_error(error)
      Rails.logger.warn("Bedrock rate limit exceeded: #{error.message}")
      raise RateLimitError.new("API rate limit exceeded: #{error.message}")
    end

    def handle_unavailable_error(error)
      Rails.logger.error("Bedrock service unavailable: #{error.message}")
      raise ModelUnavailableError.new("Service unavailable: #{error.message}")
    end

    def handle_timeout_error(error)
      Rails.logger.warn("Bedrock request timed out: #{error.message}")
      raise TimeoutError.new("Request timed out: #{error.message}")
    end

    def handle_service_error(error)
      Rails.logger.error("Bedrock service error: #{error.message}")
      raise BedrockError.new(
        "Bedrock API error: #{error.message}",
        original_error: error,
        error_type: :service_error
      )
    end

    def handle_aws_error(error)
      Rails.logger.error("AWS error: #{error.message}")
      raise BedrockError.new(
        "AWS error: #{error.message}",
        original_error: error,
        error_type: :aws_error
      )
    end
  end
end
