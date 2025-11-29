class Admin::SessionsController < Devise::SessionsController
  # 管理者用のセッション（ログイン/ログアウト）コントローラー
  # Deviseのデフォルト機能をオーバーライドしてカスタマイズ
  
  layout 'admin_auth'
  
  # Phase 2A用のコメント（Phase 2Bで有効化）
  # before_action :check_admin_path_access, only: [:new, :create]
  # before_action :configure_sign_in_params, only: [:create]
  # before_action :log_sign_in_attempt, only: [:create]
  # after_action :log_successful_sign_in, only: [:create], if: :admin_user_signed_in?
  
  def new
    # ログイン画面の表示
    @page_title = '管理者ログイン'
    
    # 既にログイン済みの場合はダッシュボードにリダイレクト
    if admin_user_signed_in?
      redirect_to admin_root_path, notice: '既にログインしています。'
      return
    end
    
    # セキュリティヘッダーの設定
    set_admin_auth_headers
    
    # Devise標準のnewアクションを実行
    super do |resource|
      # カスタム初期化処理があればここに追加
      resource.email = params[:email] if params[:email].present?
    end
  end
  
  def create
    # ログイン処理
    @page_title = '管理者ログイン'
    
    # ログイン試行の記録
    log_sign_in_attempt
    
    # セキュリティチェック
    unless valid_admin_login_request?
      flash.now[:alert] = '無効なリクエストです。'
      render :new, status: :unprocessable_entity
      return
    end
    
    # Devise標準のcreateアクションを実行
    super do |resource|
      if resource.persisted?
        # ログイン成功時の処理
        handle_successful_sign_in(resource)
      else
        # ログイン失敗時の処理
        handle_failed_sign_in
      end
    end
  end
  
  def destroy
    # ログアウト処理
    current_user_email = current_admin_user&.email
    
    # ログアウトの記録
    log_sign_out_attempt(current_user_email)
    
    # Devise標準のdestroyアクションを実行
    super do |resource|
      # カスタムログアウト処理があればここに追加
      clear_admin_session_data
    end
  end
  
  protected
  
  def after_sign_in_path_for(resource)
    # ログイン後のリダイレクト先
    stored_location_for(resource) || admin_root_path
  end
  
  def after_sign_out_path_for(resource_or_scope)
    # ログアウト後のリダイレクト先
    new_admin_user_session_path
  end
  
  private
  
  def set_admin_auth_headers
    # 管理画面認証用のセキュリティヘッダー
    response.set_header('X-Frame-Options', 'DENY')
    response.set_header('X-Content-Type-Options', 'nosniff')
    response.set_header('Cache-Control', 'no-cache, no-store, must-revalidate')
    response.set_header('Pragma', 'no-cache')
    response.set_header('Expires', '0')
  end
  
  def valid_admin_login_request?
    # 基本的なリクエスト検証
    return false unless request.post?
    return false unless params[:admin_user].present?
    return false unless params[:admin_user][:email].present?
    return false unless params[:admin_user][:password].present?
    
    # レート制限チェック（Phase 2Bで実装）
    # return false unless check_login_rate_limit
    
    true
  end
  
  def check_login_rate_limit
    # ログイン試行のレート制限（Phase 2Bで実装）
    cache_key = "admin_login_attempts:#{request.remote_ip}"
    attempts = Rails.cache.read(cache_key) || 0
    
    if attempts >= 10 # 10回/時間の制限
      Rails.logger.warn "Admin login rate limit exceeded: #{request.remote_ip}"
      return false
    end
    
    Rails.cache.write(cache_key, attempts + 1, expires_in: 1.hour)
    true
  end
  
  def log_sign_in_attempt
    # ログイン試行の記録
    Rails.logger.info "Admin login attempt: #{params[:admin_user]&.dig(:email)} from #{request.remote_ip}"
    
    # Phase 2Bで詳細ログを実装
    # AdminSecurityLog.create!(
    #   action: 'login_attempt',
    #   email: params[:admin_user]&.dig(:email),
    #   ip_address: request.remote_ip,
    #   user_agent: request.user_agent,
    #   success: false, # create時点では失敗として記録
    #   details: {
    #     remember_me: params[:admin_user]&.dig(:remember_me) == '1',
    #     referer: request.referer
    #   }
    # )
  end
  
  def handle_successful_sign_in(resource)
    # ログイン成功時の処理
    Rails.logger.info "Admin login successful: #{resource.email} from #{request.remote_ip}"
    
    # セッション情報の更新
    session[:admin_login_time] = Time.current
    session[:admin_ip_address] = request.remote_ip
    session[:admin_user_agent] = request.user_agent
    
    # 失敗回数のリセット
    # resource.reset_failed_attempts! if resource.respond_to?(:reset_failed_attempts!)
    
    # アクティビティの更新（Phase 2Bで実装）
    # resource.update!(
    #   last_sign_in_at: Time.current,
    #   last_sign_in_ip: request.remote_ip,
    #   sign_in_count: (resource.sign_in_count || 0) + 1
    # )
    
    # 成功ログの更新（Phase 2Bで実装）
    # update_security_log_success
    
    # Slack通知（Phase 2Bで実装、本番環境のみ）
    # if Rails.env.production?
    #   AdminNotificationJob.perform_async('admin_login', {
    #     admin: resource.email,
    #     ip: request.remote_ip,
    #     time: Time.current
    #   })
    # end
    
    flash[:notice] = "#{resource.display_name}さん、おかえりなさい。"
  end
  
  def handle_failed_sign_in
    # ログイン失敗時の処理
    Rails.logger.warn "Admin login failed: #{params[:admin_user]&.dig(:email)} from #{request.remote_ip}"
    
    # 失敗回数の増加（Phase 2Bで実装）
    # if (user = AdminUser.find_by(email: params[:admin_user]&.dig(:email)))
    #   user.increment_failed_attempts!
    # end
    
    # セキュリティアラート（Phase 2Bで実装）
    # if repeated_failed_attempts?
    #   SecurityAlertJob.perform_async('repeated_admin_login_failures', {
    #     ip: request.remote_ip,
    #     email: params[:admin_user]&.dig(:email),
    #     attempts: get_recent_failed_attempts_count
    #   })
    # end
    
    flash.now[:alert] = 'メールアドレスまたはパスワードが正しくありません。'
  end
  
  def log_sign_out_attempt(email)
    # ログアウトの記録
    Rails.logger.info "Admin logout: #{email} from #{request.remote_ip}"
    
    # Phase 2Bで詳細ログを実装
    # AdminSecurityLog.create!(
    #   action: 'logout',
    #   email: email,
    #   ip_address: request.remote_ip,
    #   user_agent: request.user_agent,
    #   success: true,
    #   details: {
    #     session_duration: session_duration,
    #     manual_logout: true
    #   }
    # )
  end
  
  def clear_admin_session_data
    # セッションデータのクリア
    session.delete(:admin_login_time)
    session.delete(:admin_ip_address)
    session.delete(:admin_user_agent)
    
    # その他のカスタムセッションデータがあればここでクリア
  end
  
  def session_duration
    # セッション継続時間の計算
    return 0 unless session[:admin_login_time]
    
    Time.current - Time.parse(session[:admin_login_time])
  rescue
    0
  end
  
  def repeated_failed_attempts?
    # 繰り返しログイン失敗のチェック（Phase 2Bで実装）
    cache_key = "admin_failed_attempts:#{request.remote_ip}"
    attempts = Rails.cache.read(cache_key) || 0
    attempts >= 5
  end
  
  def get_recent_failed_attempts_count
    # 最近の失敗回数を取得（Phase 2Bで実装）
    cache_key = "admin_failed_attempts:#{request.remote_ip}"
    Rails.cache.read(cache_key) || 0
  end
  
  def update_security_log_success
    # セキュリティログの成功フラグ更新（Phase 2Bで実装）
    # 最新のログエントリを成功に更新
  end
  
  def configure_sign_in_params
    # Strong parametersの設定
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password, :remember_me])
  end
  
  def check_admin_path_access
    # 管理画面パスのアクセスチェック（Phase 2Bで実装）
    # ENV['ADMIN_PATH']が設定されている場合のカスタムパスチェック
  end
end