class Api::V1::BaseController < Api::BaseController
  # Rate limiting (将来実装予定)
  # before_action :check_rate_limit

  # APIバージョン固有の設定
  before_action :set_cache_headers

  # GET /api/v1
  def info
    api_info = {
      name: "Portfolio API",
      version: "v1",
      description: "ポートフォリオサイトの公開API",
      base_url: request.base_url + "/api/v1",
      endpoints: {
        articles: {
          list: "/api/v1/articles",
          show: "/api/v1/articles/{slug}",
          search: "/api/v1/articles?search={query}"
        },
        categories: {
          list: "/api/v1/categories",
          show: "/api/v1/categories/{id}",
          articles: "/api/v1/categories/{id}/articles"
        },
        tags: {
          list: "/api/v1/tags",
          show: "/api/v1/tags/{id}",
          articles: "/api/v1/tags/{id}/articles"
        },
        sections: {
          list: "/api/v1/sections",
          show: "/api/v1/sections/{name}"
        }
      },
      documentation: request.base_url + "/docs/api",
      status: "active"
    }

    render_success(api_info)
  end

  private

  def set_cache_headers
    # 公開API用キャッシュヘッダー
    expires_in 5.minutes, public: true
  end

  # バージョン固有のメタ情報をオーバーライド
  def default_meta
    super.merge(api_version: "v1")
  end
end
