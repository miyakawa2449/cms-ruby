module AccessLogging
  extend ActiveSupport::Concern
  
  included do
    after_action :log_request_access, if: :should_log_access?
  end
  
  private
  
  def log_request_access
    # Phase 2Bで実装予定
    # AccessLogJob.perform_async(access_log_data) if Rails.env.production?
    Rails.logger.info "Access: #{request.method} #{request.path} - #{response.status} (#{request.remote_ip})"
  end
  
  def should_log_access?
    # 本番環境でのみログを記録し、ヘルスチェックや静的ファイルは除外
    return false unless Rails.env.production?
    return false if request.path.start_with?('/assets/', '/health', '/favicon.ico')
    return false if request.user_agent&.include?('HealthCheck')
    
    true
  end
  
  def access_log_data
    {
      timestamp: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      method: request.method,
      path: request.path,
      params: filtered_params,
      status_code: response.status,
      response_time_ms: calculate_response_time,
      referer: request.referer,
      device_type: @device_type,
      is_bot: bot_request?,
      admin_user_id: current_admin_user&.id,
      country_code: detect_country_code,
      session_id: request.session.id
    }
  end
  
  def filtered_params
    # パスワードやトークンなどの機密情報を除外
    params.except(:password, :password_confirmation, :token, :authenticity_token)
          .to_unsafe_h
          .slice(*permitted_log_params)
  end
  
  def permitted_log_params
    %w[id slug page per_page sort order category tag search q]
  end
  
  def calculate_response_time
    # リクエスト開始時間からの経過時間を計算
    return nil unless defined?(@request_start_time)
    
    ((Time.current - @request_start_time) * 1000).round(2)
  end
  
  def bot_request?
    user_agent = request.user_agent.to_s.downcase
    bot_patterns = [
      'bot', 'crawler', 'spider', 'scraper', 'indexer',
      'googlebot', 'bingbot', 'slurp', 'duckduckbot',
      'baiduspider', 'yandexbot', 'facebookexternalhit',
      'twitterbot', 'linkedinbot', 'whatsapp', 'telegrambot'
    ]
    
    bot_patterns.any? { |pattern| user_agent.include?(pattern) }
  end
  
  def detect_country_code
    # Phase 2Bでジオロケーション機能を実装予定
    # GeoIP.country_code(request.remote_ip) rescue nil
    nil
  end
end