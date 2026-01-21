class Admin::BaseController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_current_admin_user
  layout "admin"

  private

  def set_current_admin_user
    Current.admin_user = current_admin_user
  end

  def authenticate_admin_user!
    unless admin_user_signed_in?
      SecurityLogger.log_unauthorized_access(request.fullpath, request)
    end

    super
  end

  def after_sign_in_path_for(resource)
    admin_dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_admin_user_session_path
  end
end
