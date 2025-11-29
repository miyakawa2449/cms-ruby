module ErrorHandling
  extend ActiveSupport::Concern
  
  included do
    rescue_from StandardError, with: :handle_standard_error if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized if defined?(Pundit)
  end
  
  private
  
  def handle_standard_error(exception)
    Rails.logger.error "StandardError: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    # Log to external service (Sentry) in production
    # Sentry.capture_exception(exception) if defined?(Sentry)
    
    if api_request?
      render json: { 
        error: 'Internal server error',
        message: Rails.env.development? ? exception.message : 'Something went wrong'
      }, status: :internal_server_error
    else
      render file: Rails.public_path.join('500.html'), status: :internal_server_error, layout: false
    end
  end
  
  def handle_not_found(exception)
    Rails.logger.warn "RecordNotFound: #{exception.message}"
    
    if api_request?
      render json: { 
        error: 'Not found',
        message: 'The requested resource was not found'
      }, status: :not_found
    else
      render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
    end
  end
  
  def handle_parameter_missing(exception)
    Rails.logger.warn "ParameterMissing: #{exception.message}"
    
    if api_request?
      render json: { 
        error: 'Bad request',
        message: "Required parameter missing: #{exception.param}"
      }, status: :bad_request
    else
      redirect_back(fallback_location: root_path, alert: 'Invalid request parameters')
    end
  end
  
  def handle_not_authorized(exception)
    Rails.logger.warn "NotAuthorized: #{exception.message}"
    
    if api_request?
      render json: { 
        error: 'Forbidden',
        message: 'You are not authorized to perform this action'
      }, status: :forbidden
    else
      redirect_back(
        fallback_location: admin_signed_in? ? admin_root_path : root_path,
        alert: 'この操作を実行する権限がありません'
      )
    end
  end
end