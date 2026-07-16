class Admin::BaseController < ApplicationController
  before_action :authenticate_admin_user!
  # 2FAの強制はDevise(devise-two-factor)のログイン時OTP要求が担う。
  # かつて存在したセッションフラグによる二重ガードは、ログイン直後に
  # 無条件でフラグが立つ実装だったため機能しておらず削除した（監査M-3）
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
