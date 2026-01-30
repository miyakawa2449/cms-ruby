class Admin::BaseController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :verify_two_factor_authentication!
  before_action :ensure_admin_path_session!
  before_action :force_logout_if_admin_path_changed!
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

  def verify_two_factor_authentication!
    return unless current_admin_user&.two_factor_enabled?
    return if two_factor_authenticated?
    return if controller_name == "two_factor_auth" && action_name.in?(%w[verify verify_code])

    redirect_to verify_admin_two_factor_auth_path
  end

  def two_factor_authenticated?
    # Check if already authenticated in this session
    return true if session[:two_factor_authenticated]

    # Check for trusted device
    device_token = cookies.encrypted[:trusted_device_token]
    return true if device_token.present? && current_admin_user.device_trusted?(device_token)

    false
  end

  def after_sign_in_path_for(resource)
    admin_dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_admin_user_session_path
  end

  def ensure_admin_path_session!
    return unless admin_user_signed_in?
    return if session[:admin_path_changed_at].present?

    latest = latest_admin_path_changed_at
    session[:admin_path_changed_at] = latest.to_i if latest.present?
  end

  def force_logout_if_admin_path_changed!
    return unless admin_user_signed_in?

    latest = latest_admin_path_changed_at
    return if latest.blank?

    last_seen = session[:admin_path_changed_at].to_i
    return if last_seen.zero?
    return unless latest.to_i > last_seen

    sign_out(current_admin_user)
    reset_session
    redirect_to new_admin_user_session_path, alert: "管理画面URLが変更されたため再ログインしてください。"
  end

  def latest_admin_path_changed_at
    AdminPathHistory.order(created_at: :desc).limit(1).pick(:created_at)
  rescue StandardError => e
    Rails.logger.warn("Admin path change check failed: #{e.class} #{e.message}")
    nil
  end
end
