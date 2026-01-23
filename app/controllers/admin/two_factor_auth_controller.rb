# frozen_string_literal: true

module Admin
  # Controller for managing 2FA settings
  class TwoFactorAuthController < Admin::BaseController
    before_action :verify_password, only: %i[create destroy regenerate_backup_codes]

    # GET /admin/two_factor_auth
    def show
      @two_factor_enabled = current_admin_user.two_factor_enabled?
      @backup_codes_count = current_admin_user.backup_codes_count
    end

    # GET /admin/two_factor_auth/new
    def new
      if current_admin_user.two_factor_enabled?
        redirect_to admin_two_factor_auth_path, alert: t("two_factor_auth.already_enabled")
        return
      end

      # Generate a temporary secret for setup
      current_admin_user.otp_secret ||= AdminUser.generate_otp_secret
      current_admin_user.save!

      @qr_code = TwoFactorAuth::QrCodeGenerator.new(current_admin_user).generate
      @secret_key = current_admin_user.otp_secret
    end

    # POST /admin/two_factor_auth
    def create
      if current_admin_user.two_factor_enabled?
        redirect_to admin_two_factor_auth_path, alert: t("two_factor_auth.already_enabled")
        return
      end

      unless current_admin_user.validate_and_consume_otp!(params[:otp_code])
        redirect_to new_admin_two_factor_auth_path, alert: t("two_factor_auth.invalid_code")
        return
      end

      # Enable 2FA and generate backup codes
      current_admin_user.otp_required_for_login = true
      current_admin_user.otp_enabled_at = Time.current
      current_admin_user.save!

      @backup_codes = current_admin_user.generate_otp_backup_codes!

      # Send notification
      TwoFactorAuthMailer.enabled(current_admin_user).deliver_later
      SlackNotifier.notify_2fa_changed(current_admin_user, "enabled")

      # Mark session as 2FA-authenticated right after enable
      session[:two_factor_authenticated] = true
      session[:two_factor_authenticated_at] = Time.current.to_i

      flash[:notice] = t("two_factor_auth.enabled_success")
      render :backup_codes
    end

    # DELETE /admin/two_factor_auth
    def destroy
      unless current_admin_user.two_factor_enabled?
        redirect_to admin_two_factor_auth_path, alert: t("two_factor_auth.not_enabled")
        return
      end

      # Verify OTP code before disabling
      unless current_admin_user.validate_and_consume_otp!(params[:otp_code])
        redirect_to admin_two_factor_auth_path, alert: t("two_factor_auth.invalid_code_disable")
        return
      end

      current_admin_user.disable_two_factor!

      # Send notification
      TwoFactorAuthMailer.disabled(current_admin_user).deliver_later
      SlackNotifier.notify_2fa_changed(current_admin_user, "disabled")

      redirect_to admin_two_factor_auth_path, notice: t("two_factor_auth.disabled_success")
    end

    # POST /admin/two_factor_auth/regenerate_backup_codes
    def regenerate_backup_codes
      unless current_admin_user.two_factor_enabled?
        redirect_to admin_two_factor_auth_path, alert: t("two_factor_auth.not_enabled")
        return
      end

      @backup_codes = current_admin_user.generate_otp_backup_codes!

      # Send notification
      TwoFactorAuthMailer.backup_codes_regenerated(current_admin_user).deliver_later

      flash[:notice] = t("two_factor_auth.backup_codes_regenerated")
      render :backup_codes
    end

    # GET /admin/two_factor_auth/verify
    def verify
      # This action is called during login when 2FA is required
    end

    # POST /admin/two_factor_auth/verify
    def verify_code
      if params[:use_backup_code] == "1"
        if current_admin_user.validate_backup_code(params[:code])
          complete_two_factor_authentication
          remaining = current_admin_user.backup_codes_count
          TwoFactorAuthMailer.backup_code_used(current_admin_user, remaining).deliver_later
          return
        end
      else
        if current_admin_user.validate_and_consume_otp!(params[:code])
          handle_device_trust
          complete_two_factor_authentication
          return
        end
      end

      flash.now[:alert] = t("two_factor_auth.invalid_verification_code")
      render :verify, status: :unprocessable_entity
    end

    private

    def verify_password
      return if params[:current_password].present? &&
                current_admin_user.valid_password?(params[:current_password])

      redirect_back fallback_location: admin_two_factor_auth_path,
                    alert: t("two_factor_auth.invalid_password")
      false
    end

    def handle_device_trust
      return unless params[:trust_device] == "1"

      device_token = SecureRandom.hex(32)
      current_admin_user.trust_device!(device_token)
      cookies.encrypted[:trusted_device_token] = {
        value: device_token,
        expires: 30.days.from_now,
        httponly: true,
        secure: Rails.env.production?
      }
    end

    def complete_two_factor_authentication
      session[:two_factor_authenticated] = true
      session[:two_factor_authenticated_at] = Time.current.to_i
      redirect_to admin_dashboard_path, notice: t("two_factor_auth.verification_success")
    end
  end
end
