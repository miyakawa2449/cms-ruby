class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protect_from_forgery with: :exception

  # ApplicationHelperを明示的にinclude
  helper ApplicationHelper

  before_action :set_current_request
  after_action :reset_current_request
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def set_current_request
    Current.request = request
  end

  def reset_current_request
    Current.request = nil
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(AdminUser)
      admin_dashboard_path
    else
      root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    if resource_or_scope == :admin_user
      new_admin_user_session_path
    else
      root_path
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  # CSRF検証失敗を計測用に記録する（S1-7 P0-4）。挙動はsuper（例外）のまま変えない
  def handle_unverified_request
    SecurityLogger.log_csrf_error(request)
    super
  end
end
