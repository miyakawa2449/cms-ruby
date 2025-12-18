# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    
    # スクリプト: GTM, GA4, Clarity
    policy.script_src  :self,
                       :unsafe_inline,
                       :unsafe_eval,
                       "https://cdn.jsdelivr.net",
                       "https://www.googletagmanager.com",
                       "https://googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://www.clarity.ms",
                       "https://*.clarity.ms"
    
    # スタイル: インラインスタイル許可
    policy.style_src   :self,
                       :unsafe_inline,
                       "https://fonts.googleapis.com"
    
    # フォント: Google Fonts
    policy.font_src    :self,
                       :data,
                       "https://fonts.gstatic.com"
    
    # 画像: データURL、Google系
    policy.img_src     :self,
                       :data,
                       :https,
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://*.clarity.ms"
    
    # 接続先: GTM, GA4, Clarity
    policy.connect_src :self,
                       "https://www.google-analytics.com",
                       "https://analytics.google.com",
                       "https://*.google-analytics.com",
                       "https://*.clarity.ms",
                       "https://www.clarity.ms"
    
    # フレーム: GTMプレビュー用
    policy.frame_src   :self,
                       "https://www.googletagmanager.com"
    
    # オブジェクト: 無効化
    policy.object_src  :none
    
    # ワーカー: Clarity用
    policy.worker_src  :self, :blob
  end

  # Nonce generator（Rails 7 では通常不要だが、必要なら有効化）
  # config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report-Only モード（デバッグ時に有効化）
  # config.content_security_policy_report_only = true
end