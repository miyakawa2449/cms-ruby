# パスキー認証（WebAuthn）の設定（S1-6）
WebAuthn.configure do |config|
  # ブラウザが認証時に照合するオリジン。完全一致が必要
  config.allowed_origins =
    if Rails.env.production?
      [ "https://#{ENV.fetch('APP_HOST', 'localhost')}" ]
    else
      [ "http://localhost:3000" ]
    end

  # OSのパスキーダイアログに表示されるサービス名
  config.rp_name = ENV.fetch("SITE_NAME", "Portfolio CMS")
end
