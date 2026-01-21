# frozen_string_literal: true

# Active Storage URL Options Configuration
#
# このイニシャライザは、Active Storage がファイルURLを生成する際に
# 正しいホスト名とプロトコルを使用することを保証します。
#
# 問題: Docker環境でリバースプロキシ（nginx）の背後にRailsがある場合、
# Active Storage のディスクサービスがDockerコンテナ名（例：portfolio-web）を
# ホストとして使用してしまう。
#
# 解決策: 本番環境では明示的にホストとプロトコルを設定する。

Rails.application.config.after_initialize do
  if Rails.env.production?
    # 環境変数またはデフォルト値からURLオプションを設定
    url_options = {
      host: ENV.fetch("APP_HOST", "example.test"),
      protocol: "https"
    }

    # Routes のデフォルトURLオプションを設定
    Rails.application.routes.default_url_options = url_options

    # ActiveStorage::Current のURLオプションを設定
    ActiveStorage::Current.url_options = url_options

    Rails.logger.info "Active Storage URL options configured: #{url_options}"
  else
    # 開発・テスト環境ではHTTPを使用
    url_options = {
      host: "localhost",
      port: 3000,
      protocol: "http"
    }

    Rails.application.routes.default_url_options = url_options
    ActiveStorage::Current.url_options = url_options

    Rails.logger.info "Active Storage URL options configured for development: #{url_options}"
  end
end

# ミドルウェアを追加して、各リクエストでActiveStorage::Current.url_optionsを設定
# これにより、リダイレクトURL生成時に正しいホストが使用される
class ActiveStorageUrlOptionsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if Rails.env.production?
      # 明示的にホストを設定（X-Forwarded-Host があればそちらを優先）
      forwarded_host = env["HTTP_X_FORWARDED_HOST"]
      original_host = env["HTTP_HOST"]

      # X-Forwarded-Proto または HTTPS 環境変数からプロトコルを決定
      forwarded_proto = env["HTTP_X_FORWARDED_PROTO"]
      is_https = forwarded_proto == "https" || env["HTTPS"] == "on"

      # 信頼できるホスト名を使用（環境変数で指定されたものを優先）
      trusted_host = ENV.fetch("APP_HOST", "example.test")

      ActiveStorage::Current.url_options = {
        host: trusted_host,
        protocol: "https"
      }
    else
      # 開発・テスト環境ではHTTPを使用
      ActiveStorage::Current.url_options = {
        host: "localhost",
        port: 3000,
        protocol: "http"
      }
    end

    @app.call(env)
  end
end

# ミドルウェアを登録
Rails.application.config.middleware.insert_before 0, ActiveStorageUrlOptionsMiddleware
