# API Test Helpers for Portfolio Site
# API テスト用のヘルパーメソッド集

module ApiTestHelpers
  # ==> Authentication Helpers
  
  def api_headers(additional_headers = {})
    # API リクエスト用の基本ヘッダー
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'X-API-Version' => 'v1'
    }.merge(additional_headers)
  end
  
  def authenticated_api_headers(api_key = nil)
    # 認証済みAPIリクエスト用ヘッダー
    key = api_key || test_api_key
    api_headers('X-API-Key' => key)
  end
  
  def test_api_key
    # テスト用APIキー
    'dev_key_12345'
  end
  
  def invalid_api_key
    # 無効なAPIキー
    'invalid_key_xxx'
  end
  
  # ==> Request Helpers
  
  def api_get(path, **options)
    # API GET リクエスト
    headers = options.delete(:headers) || {}
    get path, headers: api_headers(headers), **options
  end
  
  def api_post(path, params: {}, **options)
    # API POST リクエスト
    headers = options.delete(:headers) || {}
    post path, params: params.to_json, headers: api_headers(headers), **options
  end
  
  def api_patch(path, params: {}, **options)
    # API PATCH リクエスト
    headers = options.delete(:headers) || {}
    patch path, params: params.to_json, headers: api_headers(headers), **options
  end
  
  def api_delete(path, **options)
    # API DELETE リクエスト
    headers = options.delete(:headers) || {}
    delete path, headers: api_headers(headers), **options
  end
  
  def authenticated_api_get(path, **options)
    # 認証済み API GET リクエスト
    headers = options.delete(:headers) || {}
    get path, headers: authenticated_api_headers.merge(headers), **options
  end
  
  def authenticated_api_post(path, params: {}, **options)
    # 認証済み API POST リクエスト
    headers = options.delete(:headers) || {}
    post path, params: params.to_json, headers: authenticated_api_headers.merge(headers), **options
  end
  
  def authenticated_api_patch(path, params: {}, **options)
    # 認証済み API PATCH リクエスト
    headers = options.delete(:headers) || {}
    patch path, params: params.to_json, headers: authenticated_api_headers.merge(headers), **options
  end
  
  def authenticated_api_delete(path, **options)
    # 認証済み API DELETE リクエスト
    headers = options.delete(:headers) || {}
    delete path, headers: authenticated_api_headers.merge(headers), **options
  end
  
  # ==> Response Helpers
  
  def json_response
    # JSON レスポンスのパース
    JSON.parse(response.body) if response.body.present?
  rescue JSON::ParserError
    nil
  end
  
  def expect_api_success(expected_status = :ok)
    # API 成功レスポンスの確認
    expect(response).to have_http_status(expected_status)
    expect(response.content_type).to include('application/json')
    
    json = json_response
    expect(json).to be_present
    expect(json['success']).to be true
    json
  end
  
  def expect_api_error(expected_status = :bad_request, error_message = nil)
    # API エラーレスポンスの確認
    expect(response).to have_http_status(expected_status)
    expect(response.content_type).to include('application/json')
    
    json = json_response
    expect(json).to be_present
    expect(json['success']).to be false
    expect(json['error']).to be_present
    
    if error_message
      expect(json['error']['message']).to include(error_message)
    end
    
    json
  end
  
  def expect_authentication_required
    # 認証エラーの確認
    expect_api_error(:unauthorized, 'Authentication required')
  end
  
  def expect_rate_limit_exceeded
    # レート制限エラーの確認
    expect_api_error(:too_many_requests, 'Rate limit exceeded')
  end
  
  def expect_validation_error
    # バリデーションエラーの確認
    json = expect_api_error(:unprocessable_entity, 'Validation failed')
    expect(json['error']['details']).to be_present
    json
  end
  
  def expect_not_found_error
    # リソース未発見エラーの確認
    expect_api_error(:not_found, 'Resource not found')
  end
  
  # ==> Data Validation Helpers
  
  def expect_api_meta_fields(json)
    # API メタデータフィールドの確認
    expect(json['meta']).to be_present
    expect(json['meta']['api_version']).to eq('v1')
    expect(json['meta']['timestamp']).to be_present
    expect(json['meta']['request_id']).to be_present
  end
  
  def expect_pagination_meta(json, expected_total = nil)
    # ページネーションメタデータの確認
    meta = json['meta']
    expect(meta['pagination']).to be_present
    
    pagination = meta['pagination']
    expect(pagination['current_page']).to be_present
    expect(pagination['per_page']).to be_present
    expect(pagination['total_pages']).to be_present
    expect(pagination['total_count']).to be_present
    
    if expected_total
      expect(pagination['total_count']).to eq(expected_total)
    end
    
    pagination
  end
  
  def expect_article_fields(article_data)
    # 記事データフィールドの確認
    required_fields = %w[id title slug excerpt published_at reading_time views_count]
    required_fields.each do |field|
      expect(article_data[field]).to be_present
    end
  end
  
  def expect_category_fields(category_data)
    # カテゴリデータフィールドの確認
    required_fields = %w[id name slug description articles_count]
    required_fields.each do |field|
      expect(category_data[field]).to be_present
    end
  end
  
  def expect_tag_fields(tag_data)
    # タグデータフィールドの確認
    required_fields = %w[id name slug articles_count]
    required_fields.each do |field|
      expect(tag_data[field]).to be_present
    end
  end
  
  # ==> Rate Limiting Helpers
  
  def trigger_rate_limit(path, limit = 100)
    # レート制限をトリガー
    (limit + 1).times do |i|
      api_get(path, headers: { 'X-Test-Request' => i.to_s })
      break if response.status == 429
    end
    
    expect(response).to have_http_status(:too_many_requests)
  end
  
  def check_rate_limit_headers
    # レート制限ヘッダーの確認
    expect(response.headers['X-Rate-Limit-Limit']).to be_present
    expect(response.headers['X-Rate-Limit-Remaining']).to be_present
    expect(response.headers['X-Rate-Limit-Reset']).to be_present
  end
  
  # ==> CORS Helpers
  
  def check_cors_headers
    # CORS ヘッダーの確認
    expect(response.headers['Access-Control-Allow-Origin']).to be_present
    expect(response.headers['Access-Control-Allow-Methods']).to be_present
    expect(response.headers['Access-Control-Allow-Headers']).to be_present
  end
  
  def options_request(path)
    # OPTIONS リクエスト (CORS プリフライト)
    options path, headers: api_headers
  end
  
  # ==> Test Data Helpers
  
  def create_api_test_data
    # API テスト用データ作成
    {
      articles: create_test_articles(5),
      categories: create_test_categories(3),
      tags: create_test_tags(8)
    }
  end
  
  def create_test_articles(count = 3)
    # テスト用記事データ作成
    Array.new(count) do |i|
      {
        id: i + 1,
        title: "Test Article #{i + 1}",
        slug: "test-article-#{i + 1}",
        excerpt: "This is test article #{i + 1} excerpt.",
        content: "This is the full content of test article #{i + 1}.",
        status: 'published',
        published_at: (i + 1).days.ago,
        reading_time: rand(5..15),
        views_count: rand(10..100),
        created_at: (i + 1).days.ago,
        updated_at: i.hours.ago
      }
    end
  end
  
  def create_test_categories(count = 3)
    # テスト用カテゴリデータ作成
    Array.new(count) do |i|
      {
        id: i + 1,
        name: "Category #{i + 1}",
        slug: "category-#{i + 1}",
        description: "Description for category #{i + 1}",
        articles_count: rand(5..15),
        visible: true,
        sort_order: i + 1
      }
    end
  end
  
  def create_test_tags(count = 5)
    # テスト用タグデータ作成
    Array.new(count) do |i|
      {
        id: i + 1,
        name: "Tag #{i + 1}",
        slug: "tag-#{i + 1}",
        articles_count: rand(1..10),
        visible: true
      }
    end
  end
  
  # ==> API Version Helpers
  
  def test_with_api_version(version)
    # 特定のAPIバージョンでのテスト実行
    original_version = @api_version
    @api_version = version
    
    yield
  ensure
    @api_version = original_version
  end
  
  def expect_unsupported_api_version
    # サポートされていないAPIバージョンエラーの確認
    expect_api_error(:bad_request, 'Invalid API version')
  end
  
  # ==> Performance Helpers
  
  def measure_api_response_time(&block)
    # API レスポンス時間の測定
    start_time = Time.current
    yield
    end_time = Time.current
    
    response_time = (end_time - start_time) * 1000 # ミリ秒
    expect(response_time).to be < 1000 # 1秒未満を期待
    
    response_time
  end
  
  def expect_fast_api_response(max_time_ms = 500)
    # 高速APIレスポンスの期待
    response_time = measure_api_response_time { yield }
    expect(response_time).to be < max_time_ms
  end
end