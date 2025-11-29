class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Security and CSRF protection
  protect_from_forgery with: :exception, unless: :api_request?
  skip_forgery_protection if: :api_request?
  
  # Include concerns
  include ErrorHandling
  include AccessLogging
  include SecurityHelpers
  
  # Common before actions
  before_action :set_current_admin_user
  before_action :log_access if Rails.env.production?
  before_action :detect_device_type
  before_action :set_locale
  
  # Common helpers
  helper_method :current_admin_user, :admin_signed_in?, :device_mobile?, :api_request?
  
  protected
  
  def set_current_admin_user
    # Will be implemented when Devise is configured
    # @current_admin_user ||= AdminUser.find(session[:admin_user_id]) if session[:admin_user_id]
  end
  
  def current_admin_user
    @current_admin_user
  end
  
  def admin_signed_in?
    current_admin_user.present?
  end
  
  def authenticate_admin_user!
    unless admin_signed_in?
      if api_request?
        render json: { error: 'Authentication required' }, status: :unauthorized
      else
        redirect_to admin_new_admin_user_session_path, alert: 'ログインが必要です'
      end
    end
  end
  
  def api_request?
    request.path.start_with?('/api/') || request.format.json?
  end
  
  def device_mobile?
    @device_mobile ||= request.user_agent =~ /Mobile|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i
  end
  
  def detect_device_type
    @device_type = case request.user_agent
    when /Mobile|webOS|iPhone|iPod|BlackBerry|IEMobile|Opera Mini/i
      'mobile'
    when /iPad/i
      'tablet'
    when /bot|crawler|spider|scraper/i
      'bot'
    else
      'desktop'
    end
  end
  
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  
  def not_found
    if api_request?
      render json: { error: 'Not found' }, status: :not_found
    else
      render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
    end
  end
  
  private
  
  def log_access
    # Access logging will be implemented in Phase 2B
    # AccessLogJob.perform_async(request_data) if Rails.env.production?
  end
end
