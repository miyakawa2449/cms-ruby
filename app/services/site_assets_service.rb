class SiteAssetsService
  include Rails.application.routes.url_helpers

  def initialize(request = nil)
    @request = request
  end

  def site_logo(options = {})
    begin
      logo_setting = SiteSetting.logo

      if logo_setting&.image_value&.attached?
        css_class = options[:class] || "h-8 w-auto"
        alt_text = options[:alt] || "サイトロゴ"

        # 明示的にURLを生成（polymorphic_url問題を回避）
        logo_url = Rails.application.routes.url_helpers.rails_storage_proxy_path(
          logo_setting.image_value,
          only_path: true
        )

        ApplicationController.helpers.image_tag(
          logo_url,
          class: css_class,
          alt: alt_text
        )
      else
        fallback_logo(options)
      end
    rescue => e
      Rails.logger.error "Logo display error: #{e.message}"
      fallback_logo(options)
    end
  end

  def favicon_tags
    begin
      favicon_setting = SiteSetting.favicon

      if favicon_setting&.image_value&.attached?
        favicon_url = if Rails.env.production? && @request&.host
          Rails.application.routes.url_helpers.url_for(favicon_setting.image_value)
        else
          Rails.application.routes.url_helpers.rails_blob_path(favicon_setting.image_value, only_path: true)
        end

        tags = []
        tags << favicon_link_tag(favicon_url, type: "image/png")
        tags << favicon_link_tag(favicon_url, type: "image/png", sizes: "16x16")
        tags << favicon_link_tag(favicon_url, type: "image/png", sizes: "32x32")
        tags << favicon_link_tag(favicon_url, type: "image/png", sizes: "192x192", rel: "icon")
        tags << favicon_link_tag(favicon_url, type: "image/png", sizes: "180x180", rel: "apple-touch-icon")

        tags.join("\n    ").html_safe
      else
        default_favicon_tags
      end
    rescue => e
      Rails.logger.error "Favicon display error: #{e.message}"
      default_favicon_tags
    end
  end

  def og_image_url
    og_image_setting = SiteSetting.og_image
    if og_image_setting&.image_value&.attached?
      # 開発環境では相対パスを使用、本番環境ではフルURLを生成
      if Rails.env.production? && @request&.host
        Rails.application.routes.url_helpers.url_for(og_image_setting.image_value)
      else
        Rails.application.routes.url_helpers.rails_blob_path(og_image_setting.image_value, only_path: true)
      end
    else
      default_og_image_url
    end
  end

  def favicon_icon_tags
    favicon_setting = SiteSetting.favicon
    if favicon_setting&.image_value&.attached?
      favicon_url = if Rails.env.production? && @request&.host
        Rails.application.routes.url_helpers.url_for(favicon_setting.image_value)
      else
        Rails.application.routes.url_helpers.rails_blob_path(favicon_setting.image_value, only_path: true)
      end
      [ { href: favicon_url, type: "image/png" } ]
    else
      [ { href: "/favicon.ico" } ]
    end
  end

  def safe_url_for(attachment)
    return nil unless attachment&.attached?

    begin
      # 標準的なurl_forを使用
      Rails.application.routes.url_helpers.url_for(attachment)
    rescue => e
      Rails.logger.error "URL generation error: #{e.message}"
      # 最終フォールバック
      "/images/default.jpg"
    end
  end

  private

  def fallback_logo(options = {})
    css_class = options[:class] || "h-8 w-auto"

    ApplicationController.helpers.content_tag(
      :div,
      "M",
      class: "#{css_class} flex items-center justify-center bg-gradient-to-br from-blue-900 to-slate-800 rounded-lg text-white font-bold text-xl px-3 min-w-[2rem]"
    )
  end

  def default_favicon_tags
    ApplicationController.helpers.favicon_link_tag("/favicon.ico")
  end

  def default_og_image_url
    if @request&.base_url
      "#{@request.base_url}/og-default.jpg"
    else
      "/og-default.jpg"
    end
  end

  def favicon_link_tag(*args)
    ApplicationController.helpers.favicon_link_tag(*args)
  end

  # URL生成のためのdefault_url_options
  def default_url_options
    if @request
      {
        host: @request.host,
        port: @request.port != 80 && @request.port != 443 ? @request.port : nil,
        protocol: @request.protocol.chomp("://")
      }
    else
      Rails.application.routes.default_url_options
    end
  end
end
