class Admin::SiteSettingsController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_site_settings

  def show
    @favicon = SiteSetting.favicon
    @logo = SiteSetting.logo
    @site_title = SiteSetting.site_title
    @site_description = SiteSetting.site_description
    @og_image = SiteSetting.og_image
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
          @favicon.image_value.attach(params[:site_setting][:favicon])
          if @favicon.save
            updated_count += 1
            Rails.logger.info "Favicon saved successfully"
          else
            Rails.logger.error "Favicon save failed: #{@favicon.errors.full_messages.join(', ')}"
          end
        rescue => e
          Rails.logger.error "Favicon attach error: #{e.message}"
        end
      end
      
      # ロゴの更新
      if params[:site_setting][:logo].present?
        @logo.image_value.attach(params[:site_setting][:logo])
        updated_count += 1 if @logo.save
      end
      
      # OG画像の更新
      if params[:site_setting][:og_image].present?
        @og_image.image_value.attach(params[:site_setting][:og_image])
        updated_count += 1 if @og_image.save
      end
      
      # サイトタイトルの更新
      if params[:site_setting][:site_title].present?
        @site_title.value = params[:site_setting][:site_title]
        updated_count += 1 if @site_title.save
      end
      
      # サイト説明文の更新
      if params[:site_setting][:site_description].present?
        @site_description.value = params[:site_setting][:site_description]
        updated_count += 1 if @site_description.save
      end
    end

    if updated_count > 0
      redirect_to admin_site_settings_path, notice: "サイト設定を更新しました（#{updated_count}件）"
    else
      redirect_to admin_site_settings_path, alert: '更新する内容がありません'
    end
  end

  private

  def set_site_settings
    @favicon = SiteSetting.favicon
    @logo = SiteSetting.logo
    @site_title = SiteSetting.site_title
    @site_description = SiteSetting.site_description
    @og_image = SiteSetting.og_image
  end
  
  def site_setting_params
    params.require(:site_setting).permit(:favicon, :logo, :og_image, :site_title, :site_description)
  end
end
