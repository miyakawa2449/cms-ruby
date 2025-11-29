module SecurityHelpers
  extend ActiveSupport::Concern
  
  included do
    before_action :set_security_headers
    before_action :check_rate_limits, unless: :skip_rate_limiting?
    before_action :detect_suspicious_activity
  end
  
  private
  
  def set_security_headers
    # セキュリティヘッダーの設定
    response.set_header('X-Frame-Options', 'DENY')
    response.set_header('X-Content-Type-Options', 'nosniff')
    response.set_header('X-XSS-Protection', '1; mode=block')
    response.set_header('Referrer-Policy', 'strict-origin-when-cross-origin')
    
    # HSTS（本番環境のみ）
    if Rails.env.production?
      response.set_header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload')
    end
    
    # CSP設定（Phase 2Bで詳細設定）
    unless api_request?
      csp_directives = [
        "default-src 'self'",
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com",
        "style-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com",
        "img-src 'self' data: https:",
        "font-src 'self' https:",
        "connect-src 'self' https:"
      ]
      response.set_header('Content-Security-Policy', csp_directives.join('; '))
    end
  end
  
  def check_rate_limits
    # Phase 2Bでレート制限機能を実装予定
    # return unless rate_limiting_enabled?
    
    cache_key = "rate_limit:#{request.remote_ip}:#{Time.current.to_i / 60}"
    current_count = Rails.cache.read(cache_key) || 0
    
    if current_count >= rate_limit_threshold
      Rails.logger.warn "Rate limit exceeded for IP: #{request.remote_ip}"
      
      if api_request?
        render json: { 
          error: 'Too Many Requests',
          message: 'Rate limit exceeded. Please try again later.'
        }, status: :too_many_requests
      else
        render file: Rails.public_path.join('429.html'), status: :too_many_requests, layout: false
      end
      return false
    end
    
    Rails.cache.write(cache_key, current_count + 1, expires_in: 1.minute)
  end
  
  def detect_suspicious_activity
    # 疑わしい活動の検出
    return unless Rails.env.production?
    
    suspicious_patterns = [
      /\.(php|asp|jsp|cgi)$/i,  # 存在しないスクリプトファイルへのアクセス
      /\/wp-admin|\/admin\.php/i,  # WordPress管理画面アクセス
      /\.\.|\/etc\/passwd|\/proc\//i,  # ディレクトリトラバーサル
      /<script|javascript:|vbscript:/i,  # XSSパターン
      /union.*select|drop.*table|insert.*into/i  # SQLインジェクションパターン
    ]
    
    path_and_params = "#{request.path}?#{request.query_string}"
    
    if suspicious_patterns.any? { |pattern| path_and_params.match?(pattern) }
      Rails.logger.error "Suspicious activity detected: #{request.remote_ip} - #{path_and_params}"
      
      # Phase 2Bで通知機能を実装予定
      # SecurityAlertJob.perform_async(suspicious_activity_data)
      
      render_not_found and return false
    end
  end
  
  def rate_limit_threshold
    case controller_name
    when 'sessions'
      5  # ログイン試行は厳しく制限
    when 'contacts', 'comments'
      10 # フォーム送信系は中程度
    else
      30 # 一般的なページは緩く
    end
  end
  
  def skip_rate_limiting?
    # 管理者またはローカル環境では制限をスキップ
    return true if Rails.env.development?
    return true if admin_signed_in?
    return true if request.remote_ip == '127.0.0.1'
    
    false
  end
  
  def rate_limiting_enabled?
    # Phase 2Bで設定可能にする予定
    Rails.env.production?
  end
  
  def render_not_found
    if api_request?
      render json: { error: 'Not found' }, status: :not_found
    else
      render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
    end
  end
  
  def suspicious_activity_data
    {
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      path: request.path,
      params: request.parameters,
      method: request.method,
      timestamp: Time.current,
      severity: 'medium'
    }
  end
  
  def secure_compare(a, b)
    # タイミング攻撃を防ぐための安全な文字列比較
    ActiveSupport::SecurityUtils.secure_compare(a.to_s, b.to_s)
  end
end