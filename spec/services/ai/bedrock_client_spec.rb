require 'rails_helper'

RSpec.describe Ai::BedrockClient do
  let(:client) { described_class.new }
  let(:model_id) { 'anthropic.claude-3-haiku-20240307-v1:0' }
  let(:prompt) { 'テストプロンプト' }

  around do |example|
    old_access_key = ENV["AWS_ACCESS_KEY_ID"]
    old_secret_key = ENV["AWS_SECRET_ACCESS_KEY"]
    old_region = ENV["AWS_REGION"]

    ENV["AWS_ACCESS_KEY_ID"] = "test-access-key"
    ENV["AWS_SECRET_ACCESS_KEY"] = "test-secret-key"
    ENV["AWS_REGION"] = "us-east-1"

    example.run
  ensure
    ENV["AWS_ACCESS_KEY_ID"] = old_access_key
    ENV["AWS_SECRET_ACCESS_KEY"] = old_secret_key
    ENV["AWS_REGION"] = old_region
  end

  before do
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(
      instance_double(Aws::BedrockRuntime::Client, invoke_model: nil)
    )
  end

  describe '#invoke_model' do
    context '正常系' do
      it 'モデルを呼び出してレスポンスを返す' do
        mock_bedrock_client(
          response_content: '生成されたテキスト',
          tokens: { input: 100, output: 50 }
        )

        result = client.invoke_model(model_id, prompt)

        expect(result[:content]).to eq('生成されたテキスト')
        expect(result[:usage][:input_tokens]).to eq(100)
        expect(result[:usage][:output_tokens]).to eq(50)
      end

      it 'max_tokensパラメータを受け付ける' do
        mock_bedrock_client(response_content: 'テスト')

        # Simply verify the call succeeds with custom max_tokens
        result = client.invoke_model(model_id, prompt, max_tokens: 1000)
        expect(result[:content]).to eq('テスト')
      end
    end

    context '異常系' do
      it 'model_idが空の場合、ValidationErrorを発生させる' do
        expect {
          client.invoke_model('', prompt)
        }.to raise_error(Ai::ValidationError, /Model ID is required/)
      end

      it 'promptが空の場合、ValidationErrorを発生させる' do
        expect {
          client.invoke_model(model_id, '')
        }.to raise_error(Ai::ValidationError, /Prompt is required/)
      end

      it 'promptが長すぎる場合、ValidationErrorを発生させる' do
        long_prompt = 'a' * 100_001
        expect {
          client.invoke_model(model_id, long_prompt)
        }.to raise_error(Ai::ValidationError, /too long/)
      end

      it 'API エラー時にBedrockErrorを発生させる' do
        mock_bedrock_error(
          error_class: Aws::BedrockRuntime::Errors::ServiceError,
          message: 'Service Error'
        )

        expect {
          client.invoke_model(model_id, prompt)
        }.to raise_error(Ai::BedrockError)
      end

      it 'レート制限エラーでRateLimitErrorを発生させる' do
        mock_bedrock_throttling

        expect {
          client.invoke_model(model_id, prompt)
        }.to raise_error(Ai::RateLimitError)
      end

      it 'サービス利用不可エラーでModelUnavailableErrorを発生させる' do
        mock_bedrock_error(
          error_class: Aws::BedrockRuntime::Errors::ServiceUnavailableException,
          message: 'Service Unavailable'
        )

        expect {
          client.invoke_model(model_id, prompt)
        }.to raise_error(Ai::ModelUnavailableError)
      end
    end
  end

  describe '#invoke_model_with_retry' do
    context 'リトライ成功' do
      it '一時的なエラー後にリトライして成功する' do
        call_count = 0
        bedrock = instance_double(Aws::BedrockRuntime::Client)
        allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock)

        allow(bedrock).to receive(:invoke_model) do
          call_count += 1
          if call_count < 2
            raise Aws::BedrockRuntime::Errors::ThrottlingException.new(nil, 'Rate limit')
          else
            response_body = {
              'content' => [ { 'text' => '成功' } ],
              'usage' => { 'input_tokens' => 10, 'output_tokens' => 5 }
            }.to_json
            double(body: StringIO.new(response_body))
          end
        end

        # Sleep を無効化
        allow(client).to receive(:sleep)

        result = client.invoke_model_with_retry(model_id, prompt, max_retries: 3)
        expect(result[:content]).to eq('成功')
        expect(call_count).to eq(2)
      end
    end

    context 'リトライ失敗' do
      it '最大リトライ回数後にエラーを発生させる' do
        mock_bedrock_throttling
        allow(client).to receive(:sleep)

        expect {
          client.invoke_model_with_retry(model_id, prompt, max_retries: 2)
        }.to raise_error(Ai::RateLimitError)
      end
    end
  end
end
