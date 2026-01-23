class AdminUsers::SessionsController < Devise::SessionsController
  layout "admin_auth"
  after_action :ensure_security_headers

  protected

  def after_sign_in_path_for(resource)
    if resource.two_factor_enabled?
      session[:two_factor_authenticated] = true
      session[:two_factor_authenticated_at] = Time.current.to_i
    end

    stored_location_for(resource) || admin_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    # Clear 2FA session data on sign out
    session.delete(:two_factor_authenticated)
    session.delete(:two_factor_authenticated_at)
    new_admin_user_session_path
  end

  private

  def two_factor_authenticated?(resource)
    # Check if already authenticated in this session
    return true if session[:two_factor_authenticated]

    # Check for trusted device
    device_token = cookies.encrypted[:trusted_device_token]
    return true if device_token.present? && resource.device_trusted?(device_token)

    false
  end

  def ensure_security_headers
    response.headers["X-Frame-Options"] ||= "SAMEORIGIN"
    response.headers["X-Content-Type-Options"] ||= "nosniff"
  end
end
