# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # 開発環境ではHTTPを許可、本番環境ではHTTPS必須
    if Rails.env.development? || Rails.env.test?
      policy.default_src :self
    else
      policy.default_src :self, :https
    end

    # スクリプト: GTM, GA4, Clarity, 埋め込みコンテンツ用
    policy.script_src  :self,
                       :unsafe_inline,
                       :unsafe_eval,
                       "https://cdn.jsdelivr.net",
                       "https://www.googletagmanager.com",
                       "https://googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://www.clarity.ms",
                       "https://*.clarity.ms",
                       # X (Twitter) 埋め込み用
                       "https://platform.twitter.com",
                       "https://platform.x.com",
                       # YouTube 埋め込み用
                       "https://www.youtube.com",
                       # Facebook 埋め込み用
                       "https://connect.facebook.net",
                       "https://www.facebook.com",
                       # Instagram 埋め込み用
                       "https://www.instagram.com",
                       # Threads 埋め込み用
                       "https://www.threads.net"

    # スタイル: インラインスタイル許可
    policy.style_src   :self,
                       :unsafe_inline,
                       "https://fonts.googleapis.com",
                       # CDN (Cropper.js等)
                       "https://cdn.jsdelivr.net",
                       # X (Twitter) 埋め込み用
                       "https://platform.twitter.com",
                       "https://platform.x.com"

    # フォント: Google Fonts
    policy.font_src    :self,
                       :data,
                       "https://fonts.gstatic.com"

    # 画像: データURL、Google系、埋め込みコンテンツ用
    policy.img_src     :self,
                       :data,
                       :https,
                       :blob,
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://*.clarity.ms",
                       # X (Twitter) 埋め込み用
                       "https://pbs.twimg.com",
                       "https://abs.twimg.com",
                       "https://platform.twitter.com",
                       # YouTube サムネイル用
                       "https://i.ytimg.com",
                       "https://img.youtube.com",
                       # Facebook 埋め込み用
                       "https://www.facebook.com",
                       "https://static.xx.fbcdn.net",
                       "https://*.fbcdn.net",
                       # Instagram 埋め込み用
                       "https://www.instagram.com",
                       "https://*.cdninstagram.com",
                       "https://scontent.cdninstagram.com",
                       # Threads 埋め込み用
                       "https://www.threads.net",
                       "https://*.threads.net"

    # 接続先: GTM, GA4, Clarity
    policy.connect_src :self,
                       "https://www.google-analytics.com",
                       "https://analytics.google.com",
                       "https://*.google-analytics.com",
                       "https://*.clarity.ms",
                       "https://www.clarity.ms"

    # フレーム: GTMプレビュー、YouTube、X (Twitter)、Facebook、Instagram、Threads 埋め込み用
    policy.frame_src   :self,
                       "https://www.googletagmanager.com",
                       # YouTube 埋め込み用
                       "https://www.youtube.com",
                       "https://youtube.com",
                       "https://www.youtube-nocookie.com",
                       # X (Twitter) 埋め込み用
                       "https://platform.twitter.com",
                       "https://twitter.com",
                       "https://x.com",
                       "https://platform.x.com",
                       # Facebook 埋め込み用
                       "https://www.facebook.com",
                       "https://facebook.com",
                       "https://web.facebook.com",
                       # Instagram 埋め込み用
                       "https://www.instagram.com",
                       "https://instagram.com",
                       # Threads 埋め込み用
                       "https://www.threads.net",
                       "https://threads.net"

    # オブジェクト: 無効化
    policy.object_src  :none

    # ワーカー: Clarity用、Active Storage用
    policy.worker_src  :self, :blob

    # メディア: Active Storage用
    policy.media_src   :self, :blob, :https
  end

  # Nonce generator（Rails 7 では通常不要だが、必要なら有効化）
  # config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report-Only モード（デバッグ時に有効化）
  # config.content_security_policy_report_only = true
end
