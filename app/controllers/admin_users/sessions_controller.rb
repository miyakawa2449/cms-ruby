class AdminUsers::SessionsController < Devise::SessionsController
  layout "admin_auth"
  after_action :ensure_security_headers

  protected

  def after_sign_in_path_for(resource)
    latest = AdminPathHistory.order(created_at: :desc).limit(1).pick(:created_at)
    session[:admin_path_changed_at] = latest.to_i if latest.present?

    stored_location_for(resource) || admin_root_path
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
