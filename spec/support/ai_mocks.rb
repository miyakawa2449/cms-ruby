# Helper module for mocking AI services in tests
module AiMocks
  # Mock a successful Bedrock client response
  def mock_bedrock_client(response_content:, tokens: { input: 100, output: 50 })
    bedrock_client = instance_double(Aws::BedrockRuntime::Client)
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)

    response_body = {
      'content' => [ { 'text' => response_content } ],
      'usage' => {
        'input_tokens' => tokens[:input],
        'output_tokens' => tokens[:output]
      }
    }.to_json

    response = double(body: StringIO.new(response_body))
    allow(bedrock_client).to receive(:invoke_model).and_return(response)

    bedrock_client
  end

  # Mock a Bedrock error
  def mock_bedrock_error(error_class: Aws::BedrockRuntime::Errors::ServiceError, message: 'API Error')
    bedrock_client = instance_double(Aws::BedrockRuntime::Client)
    allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(bedrock_client)
    allow(bedrock_client).to receive(:invoke_model).and_raise(error_class.new(nil, message))

    bedrock_client
  end

  # Mock a throttling error
  def mock_bedrock_throttling
    mock_bedrock_error(
      error_class: Aws::BedrockRuntime::Errors::ThrottlingException,
      message: 'Rate limit exceeded'
    )
  end

  # Build a mock summary response
  def mock_summary_response(count: 3)
    summaries = count.times.map { |i| { text: "テスト要約#{i + 1}", length: 80 } }
    { summaries: summaries }.to_json
  end

  # Build a mock tag response
  def mock_tag_response(tags: nil)
    tags ||= [
      { name: 'Ruby', confidence: 0.95, existing: true },
      { name: 'Rails', confidence: 0.90, existing: true },
      { name: '新規タグ', confidence: 0.85, existing: false }
    ]
    { tags: tags }.to_json
  end

  # Build a mock slug response
  def mock_slug_response(slugs: nil)
    slugs ||= [
      { slug: 'test-article-slug', seo_score: 95 },
      { slug: 'sample-post', seo_score: 88 }
    ]
    { slugs: slugs }.to_json
  end

  # Build a mock SEO meta response
  def mock_seo_meta_response
    {
      meta_description: 'テスト用のメタディスクリプションです。',
      meta_keywords: 'Ruby, Rails, テスト',
      og_title: 'テスト記事のOGタイトル',
      og_description: 'OG用の説明文です。'
    }.to_json
  end

  # Build a mock structure response
  def mock_structure_response
    {
      title_suggestions: [ 'タイトル案1', 'タイトル案2' ],
      sections: [
        { heading: 'はじめに', level: 2, description: '導入部分', recommended_words: 200 },
        { heading: '本文', level: 2, description: '主要コンテンツ', recommended_words: 800 }
      ],
      total_recommended_words: 1500,
      related_topics: [ '関連トピック1' ],
      keywords: [ 'キーワード1', 'キーワード2' ]
    }.to_json
  end
end

RSpec.configure do |config|
  config.include AiMocks
end
