# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    if Rails.env.development? || Rails.env.test?
      policy.default_src :self
    else
      policy.default_src :self, :https
    end

    policy.script_src :self,
                      :https,
                      "https://cdn.jsdelivr.net",
                      "https://www.googletagmanager.com",
                      "https://googletagmanager.com",
                      "https://www.google-analytics.com",
                      "https://ssl.google-analytics.com",
                      "https://www.clarity.ms",
                      "https://*.clarity.ms",
                      "https://platform.twitter.com",
                      "https://platform.x.com",
                      "https://www.youtube.com",
                      "https://connect.facebook.net",
                      "https://www.facebook.com",
                      "https://www.instagram.com",
                      "https://www.threads.net"

    policy.style_src :self,
                     :https,
                     :unsafe_inline,
                      "https://fonts.googleapis.com",
                      "https://cdn.jsdelivr.net",
                     "https://www.googletagmanager.com",
                     "https://platform.twitter.com",
                     "https://platform.x.com"

    policy.font_src :self, :https, :data, "https://fonts.gstatic.com"

    policy.img_src :self,
                   :data,
                   :https,
                   :blob,
                   "https://www.googletagmanager.com",
                   "https://www.google-analytics.com",
                   "https://*.clarity.ms",
                   "https://c.bing.com",
                   "https://pbs.twimg.com",
                   "https://abs.twimg.com",
                   "https://platform.twitter.com",
                   "https://i.ytimg.com",
                   "https://img.youtube.com",
                   "https://www.facebook.com",
                   "https://static.xx.fbcdn.net",
                   "https://*.fbcdn.net",
                   "https://www.instagram.com",
                   "https://*.cdninstagram.com",
                   "https://scontent.cdninstagram.com",
                   "https://www.threads.net",
                   "https://*.threads.net"

    policy.connect_src :self,
                       "https://www.google-analytics.com",
                       "https://analytics.google.com",
                       "https://*.google-analytics.com",
                       "https://*.clarity.ms",
                       "https://www.clarity.ms",
                       "https://c.bing.com"

    policy.frame_src :self,
                     "https://www.googletagmanager.com",
                     "https://www.youtube.com",
                     "https://youtube.com",
                     "https://www.youtube-nocookie.com",
                     "https://platform.twitter.com",
                     "https://twitter.com",
                     "https://x.com",
                     "https://platform.x.com",
                     "https://www.facebook.com",
                     "https://facebook.com",
                     "https://web.facebook.com",
                     "https://www.instagram.com",
                     "https://instagram.com",
                     "https://www.threads.net",
                     "https://threads.net"

    policy.object_src :none
    policy.worker_src :self, :blob
    policy.media_src :self, :blob, :https

    policy.base_uri :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.upgrade_insecure_requests if Rails.env.production?

    if Rails.env.development? || Rails.env.test?
      policy.script_src :unsafe_inline, :unsafe_eval
    end
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  if Rails.env.production?
    config.content_security_policy_report_only = false
  end
end
