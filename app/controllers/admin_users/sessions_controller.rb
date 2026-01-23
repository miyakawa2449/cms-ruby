class AdminUsers::SessionsController < Devise::SessionsController
  layout "admin_auth"
  after_action :ensure_security_headers

  protected

  def after_sign_in_path_for(resource)
    admin_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_admin_user_session_path
  end

  private

  def ensure_security_headers
    response.headers["X-Frame-Options"] ||= "SAMEORIGIN"
    response.headers["X-Content-Type-Options"] ||= "nosniff"
  end
end
