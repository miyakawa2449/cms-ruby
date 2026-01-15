class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protect_from_forgery with: :exception

  # ApplicationHelperを明示的にinclude
  helper ApplicationHelper

  # Content Security Policy
  before_action :set_csp_header

  private

  def set_csp_header
    # Skip CSP for admin pages to avoid issues with third-party libraries
    return if request.path.start_with?("/admin")

    response.headers["Content-Security-Policy"] = [
      "default-src 'self'",
      # スクリプト: GTM, GA4, Clarity, SNS埋め込み
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://www.googletagmanager.com https://googletagmanager.com https://www.google-analytics.com https://ssl.google-analytics.com https://www.clarity.ms https://*.clarity.ms https://www.youtube.com https://www.instagram.com https://connect.facebook.net https://platform.twitter.com https://platform.x.com",
      # スタイル: Google Fonts
      "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://fonts.googleapis.com https://www.googletagmanager.com https://platform.twitter.com",
      # 画像: Google系, Clarity, SNS
      "img-src 'self' data: https: blob: https://www.googletagmanager.com https://www.google-analytics.com https://*.clarity.ms https://c.bing.com https://*.twimg.com https://*.cdninstagram.com https://*.fbcdn.net https://i.ytimg.com",
      # フォント: Google Fonts
      "font-src 'self' https: data: https://fonts.gstatic.com",
      # 接続先: GA4, Clarity
      "connect-src 'self' https://www.google-analytics.com https://analytics.google.com https://*.google-analytics.com https://*.clarity.ms https://www.clarity.ms https://c.bing.com",
      # メディア
      "media-src 'self' https://www.youtube.com https://*.youtube.com",
      # オブジェクト: 無効化
      "object-src 'none'",
      # ベースURI
      "base-uri 'self'",
      # フォームアクション
      "form-action 'self'",
      # フレーム: GTM, YouTube, Instagram, Facebook, Twitter
      "frame-src 'self' https://www.googletagmanager.com https://www.youtube.com https://www.youtube-nocookie.com https://www.instagram.com https://www.facebook.com https://platform.twitter.com https://twitter.com https://x.com",
      # 親フレーム
      "frame-ancestors 'none'",
      # Worker: Clarity用
      "worker-src 'self' blob:",
      # HTTPSアップグレード
      "upgrade-insecure-requests"
    ].join("; ")
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(AdminUser)
      admin_dashboard_path
    else
      root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    if resource_or_scope == :admin_user
      new_admin_user_session_path
    else
      root_path
    end
  end
end
