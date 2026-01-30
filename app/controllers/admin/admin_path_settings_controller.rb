module Admin
  class AdminPathSettingsController < Admin::BaseController
    def edit
      @current_path = AdminPath::Resolver.current_path
      @histories = AdminPathHistory.recent.includes(:admin_user)
      @rotation_enabled = ENV.fetch("ADMIN_PATH_ROTATION_ENABLED", "false") == "true"
      @rotation_frequency = ENV.fetch("ADMIN_PATH_ROTATION_FREQUENCY", "monthly")
      @next_rotation_at = calculate_next_rotation
    end

    def update
      result = AdminPath::Updater.new(
        admin_user: current_admin_user,
        new_path: params[:new_path],
        change_type: :manual,
        reason: params[:reason]
      ).call

      if result[:success]
        sign_out(current_admin_user)
        reset_session
        redirect_to new_admin_user_session_path,
                    notice: "管理画面URLを変更しました。再ログインしてください。"
      else
        flash[:alert] = "URL変更に失敗しました: #{result[:error]}"
        redirect_to edit_admin_admin_path_settings_path
      end
    end

    def emergency_rotation
      new_path = generate_emergency_path
      result = AdminPath::Updater.new(
        admin_user: current_admin_user,
        new_path: new_path,
        change_type: :emergency,
        reason: params[:reason] || "緊急ローテーション"
      ).call

      if result[:success]
        sign_out(current_admin_user)
        reset_session
        redirect_to new_admin_user_session_path,
                    notice: "緊急ローテーションを実行しました。再ログインしてください。"
      else
        flash[:alert] = "緊急ローテーションに失敗しました: #{result[:error]}"
        redirect_to edit_admin_admin_path_settings_path
      end
    end

    private

    def calculate_next_rotation
      return nil unless ENV.fetch("ADMIN_PATH_ROTATION_ENABLED", "false") == "true"

      frequency = ENV.fetch("ADMIN_PATH_ROTATION_FREQUENCY", "monthly")
      case frequency
      when "weekly"
        1.week.from_now
      when "monthly"
        1.month.from_now
      when "quarterly"
        3.months.from_now
      else
        1.month.from_now
      end
    end

    def generate_emergency_path
      "emergency-admin-#{SecureRandom.hex(6)}"
    end
  end
end
