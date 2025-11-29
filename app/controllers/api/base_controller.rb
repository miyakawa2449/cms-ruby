class Api::BaseController < ApplicationController
  # API用の基本コントローラー
  # すべてのAPIエンドポイントの親クラス
  
  # APIではHTMLレイアウトは使用しない
  layout false
  
  # CSRF保護をスキップ（APIトークンベース認証を使用）
  skip_forgery_protection
  
  # API用の共通設定
  before_action :set_default_response_format
  before_action :validate_api_version
  before_action :authenticate_api_request
  before_action :set_cors_headers
  before_action :rate_limit_api_requests
  
  # API用のエラーハンドリング
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_errors
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from StandardError, with: :render_internal_error
  
  protected
  
  def set_default_response_format
    request.format = :json unless params[:format]
  end
  
  def validate_api_version
    api_version = request.headers['X-API-Version'] || extract_version_from_path
    
    unless valid_api_version?(api_version)
      render_api_error(
        'Invalid API version',
        "Supported versions: #{supported_api_versions.join(', ')}",
        :bad_request
      )
      return false
    end
    
    @api_version = api_version
  end
  
  def authenticate_api_request
    # APIキー認証（Phase 2Bで実装）
    api_key = request.headers['X-API-Key'] || params[:api_key]
    
    if api_key.blank?
      render_authentication_required
      return false
    end
    
    # @api_client = ApiClient.find_by(api_key: api_key, active: true)
    # 
    # unless @api_client
    #   render_invalid_credentials
    #   return false
    # end
    
    # Phase 2A用の仮実装（開発用APIキーのみ許可）
    unless valid_development_api_key?(api_key)
      render_invalid_credentials
      return false
    end
    
    # APIクライアント情報を記録
    @current_api_client = { id: 'dev', name: 'Development Client' }
  end
  
  def set_cors_headers
    # CORS設定
    response.set_header('Access-Control-Allow-Origin', cors_allowed_origins)
    response.set_header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
    response.set_header('Access-Control-Allow-Headers', 'Content-Type, X-API-Key, X-API-Version, Authorization')
    response.set_header('Access-Control-Max-Age', '86400')
    
    # プリフライトリクエストへの対応
    if request.method == 'OPTIONS'
      render json: {}, status: :ok
      return
    end
  end
  
  def rate_limit_api_requests
    # API用のレート制限（Phase 2Bで詳細実装）
    client_identifier = @current_api_client&.dig(:id) || request.remote_ip
    cache_key = "api_rate_limit:#{client_identifier}:#{Time.current.to_i / 60}"
    
    current_requests = Rails.cache.read(cache_key) || 0
    limit = api_rate_limit
    
    if current_requests >= limit
      response.set_header('X-Rate-Limit-Limit', limit.to_s)
      response.set_header('X-Rate-Limit-Remaining', '0')
      response.set_header('X-Rate-Limit-Reset', (Time.current + 1.minute).to_i.to_s)
      
      render_api_error(
        'Rate limit exceeded',
        "API rate limit of #{limit} requests per minute exceeded",
        :too_many_requests
      )
      return false
    end
    
    Rails.cache.write(cache_key, current_requests + 1, expires_in: 1.minute)
    
    # レート制限ヘッダーの設定
    response.set_header('X-Rate-Limit-Limit', limit.to_s)
    response.set_header('X-Rate-Limit-Remaining', (limit - current_requests - 1).to_s)
    response.set_header('X-Rate-Limit-Reset', (Time.current + 1.minute).to_i.to_s)
  end
  
  # 標準的なAPIレスポンスメソッド
  def render_success(data = nil, message = nil, status = :ok, meta = {})
    response_data = {
      success: true,
      data: data,
      message: message,
      meta: build_response_meta.merge(meta)
    }.compact
    
    render json: response_data, status: status
  end
  
  def render_error(message, details = nil, status = :bad_request, error_code = nil)
    render json: {
      success: false,
      error: {
        message: message,
        details: details,
        code: error_code
      }.compact,
      meta: build_response_meta
    }, status: status
  end
  
  def render_validation_errors(exception)
    render_error(
      'Validation failed',
      exception.record.errors.full_messages,
      :unprocessable_entity,
      'VALIDATION_ERROR'
    )
  end
  
  def render_not_found(exception = nil)
    render_error(
      'Resource not found',
      exception&.message,
      :not_found,
      'NOT_FOUND'
    )
  end
  
  def render_parameter_missing(exception)
    render_error(
      'Required parameter missing',
      "Parameter '#{exception.param}' is required",
      :bad_request,
      'PARAMETER_MISSING'
    )
  end
  
  def render_internal_error(exception)
    Rails.logger.error "API Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    message = Rails.env.development? ? exception.message : 'Internal server error'
    render_error(message, nil, :internal_server_error, 'INTERNAL_ERROR')
  end
  
  def render_authentication_required
    render_error(
      'Authentication required',
      'API key is required to access this endpoint',
      :unauthorized,
      'AUTHENTICATION_REQUIRED'
    )
  end
  
  def render_invalid_credentials
    render_error(
      'Invalid credentials',
      'The provided API key is invalid or expired',
      :unauthorized,
      'INVALID_CREDENTIALS'
    )
  end
  
  # ページネーション用のメタデータを構築
  def pagination_meta(collection)
    return {} unless collection.respond_to?(:current_page)
    
    {
      pagination: {
        current_page: collection.current_page,
        per_page: collection.limit_value,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        next_page: collection.next_page,
        prev_page: collection.prev_page
      }
    }
  end
  
  private
  
  def valid_api_version?(version)
    supported_api_versions.include?(version)
  end
  
  def supported_api_versions
    %w[v1]
  end
  
  def extract_version_from_path
    # URLパスからAPIバージョンを抽出 (/api/v1/...)
    path_parts = request.path.split('/')
    api_index = path_parts.index('api')
    return nil unless api_index && api_index + 1 < path_parts.length
    
    version = path_parts[api_index + 1]
    version if version.match?(/^v\d+$/)
  end
  
  def valid_development_api_key?(api_key)
    # Phase 2A用の開発環境APIキー検証
    development_keys = [
      'dev_key_12345',
      'portfolio_dev_api_key',
      ENV['DEVELOPMENT_API_KEY']
    ].compact
    
    development_keys.include?(api_key)
  end
  
  def cors_allowed_origins
    origins = ENV['CORS_ALLOWED_ORIGINS']&.split(',') || []
    
    if Rails.env.development?
      origins += ['http://localhost:3000', 'http://127.0.0.1:3000']
    end
    
    origins.any? ? origins.join(', ') : '*'
  end
  
  def api_rate_limit
    case @api_version
    when 'v1'
      @current_api_client&.dig(:id) == 'dev' ? 1000 : 100 # 開発用は緩い制限
    else
      60
    end
  end
  
  def build_response_meta
    {
      api_version: @api_version,
      timestamp: Time.current.iso8601,
      request_id: request.uuid
    }
  end
  
  def render_api_error(title, message, status)
    render json: {
      success: false,
      error: {
        message: title,
        details: message
      },
      meta: build_response_meta
    }, status: status
  end
end