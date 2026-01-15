class Admin::SiteSettingsController < Admin::BaseController
  before_action :set_site_settings

  def show
    @favicon = SiteSetting.favicon
    @logo = SiteSetting.logo
    @site_title = SiteSetting.site_title
    @site_description = SiteSetting.site_description
    @og_image = SiteSetting.og_image
    @gtm_id = SiteSetting.gtm_id
    render :index
  end

  def update
    updated_count = 0

    # デバッグ用ログ出力
    Rails.logger.info "=== Site Settings Update Params ==="
    Rails.logger.info params.inspect

    if params[:site_setting]
      # Faviconの更新
      if params[:site_setting][:favicon].present?
        begin
          result = @favicon.value_manager.update_value(params[:site_setting][:favicon])
          if result[:valid]
            updated_count += 1
            Rails.logger.info "Favicon updated successfully"
          else
            Rails.logger.error "Favicon update failed: #{result[:errors]}"
          end
        rescue => e
          Rails.logger.error "Favicon update error: #{e.message}"
        end
      end

      # ロゴの更新
      if params[:site_setting][:logo].present?
        result = @logo.value_manager.update_value(params[:site_setting][:logo])
        updated_count += 1 if result[:valid]
      end

      # OG画像の更新
      if params[:site_setting][:og_image].present?
        result = @og_image.value_manager.update_value(params[:site_setting][:og_image])
        updated_count += 1 if result[:valid]
      end

      # サイトタイトルの更新
      if params[:site_setting][:site_title].present?
        result = @site_title.value_manager.update_value(params[:site_setting][:site_title])
        if result[:valid]
          updated_count += 1
          Rails.logger.info "Site title updated successfully"
        else
          Rails.logger.error "Site title update failed: #{result[:errors]}"
        end
      end

      # サイト説明文の更新
      if params[:site_setting][:site_description].present?
        result = @site_description.value_manager.update_value(params[:site_setting][:site_description])
        if result[:valid]
          updated_count += 1
          Rails.logger.info "Site description updated successfully"
        else
          Rails.logger.error "Site description update failed: #{result[:errors]}"
        end
      end

      # Google Tag Manager IDの更新
      if params[:site_setting].has_key?(:gtm_id)
        result = @gtm_id.value_manager.update_value(params[:site_setting][:gtm_id])
        if result[:valid]
          updated_count += 1
          Rails.logger.info "GTM ID updated successfully"
        else
          Rails.logger.error "GTM ID update failed: #{result[:errors]}"
        end
      end
    end

    if updated_count > 0
      redirect_to admin_site_settings_path, notice: "サイト設定を更新しました（#{updated_count}件）"
    else
      redirect_to admin_site_settings_path, alert: "更新する内容がありません"
    end
  end

  private

  def set_site_settings
    @favicon = SiteSetting.favicon
    @logo = SiteSetting.logo
    @site_title = SiteSetting.site_title
    @site_description = SiteSetting.site_description
    @og_image = SiteSetting.og_image
    @gtm_id = SiteSetting.gtm_id
  end

  def site_setting_params
    params.require(:site_setting).permit(:favicon, :logo, :og_image, :site_title, :site_description, :gtm_id)
  end
end
