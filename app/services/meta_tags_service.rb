class MetaTagsService
  include Rails.application.routes.url_helpers

  def initialize(request = nil)
    @request = request
  end

  def article_meta_tags(article)
    description = article.meta_description.presence ||
                 article.excerpt.presence ||
                 truncate(strip_tags(article.content), length: 160)

    keywords = article.meta_keywords.presence || article.tags.pluck(:name).join(",")

    og_title = article.og_title.presence || article.title
    og_description = article.og_description.presence || description
    og_image = if article.ogp_image.attached?
                 if article.ogp_image.variable?
                   Rails.application.routes.url_helpers.url_for(
                     article.ogp_image.variant(resize_to_limit: [1200, 630])
                   )
                 else
                   safe_url_for(article.ogp_image)
                 end
    elsif article.thumbnail_image.attached?
                 if article.thumbnail_image.variable?
                   # OGP用は1200x630を基準にセンタークロップ
                   Rails.application.routes.url_helpers.url_for(
                     article.thumbnail_image.variant(resize_to_fill: [1200, 630])
                   )
                 else
                   safe_url_for(article.thumbnail_image)
                 end
    else
                 default_og_image_url
    end

    build_meta_tags(
      title: article.title,
      description: description,
      keywords: keywords,
      og: {
        title: og_title,
        description: og_description,
        type: "article",
        image: og_image,
        article: {
          published_time: article.published_at&.iso8601,
          author: article.admin_user.email,
          tag: article.tags.pluck(:name)
        }
      },
      twitter: {
        title: og_title,
        description: og_description,
        image: og_image
      }
    )
  end

  def portfolio_meta_tags
    title = SiteSetting.site_title.value.presence ||
           "宮川 剛 - シニアエンジニアのポートフォリオ"
    description = SiteSetting.site_description.value.presence ||
                 "要件定義からプログラミングまで一人でできるエンジニア、宮川剛のポートフォリオサイト。20年以上の経験を活かしたシステム設計・開発を提供します。"

    build_meta_tags(
      title: title,
      description: description,
      keywords: "ポートフォリオ,エンジニア,システムエンジニア,プロジェクトマネージャ,Ruby on Rails,AI,ChatGPT",
      og: {
        title: title,
        description: description,
        type: "website",
        image: default_og_image_url
      },
      twitter: {
        title: title,
        description: description,
        image: default_og_image_url
      }
    )
  end

  def blog_top_meta_tags
    title = "Miyakawa Codes Blog | 宮川 剛"
    description = "技術情報やプロジェクト進捗を発信するブログページです。最新の技術トレンドや開発ノウハウをお届けします。"

    build_meta_tags(
      title: title,
      description: description,
      keywords: "ブログ,技術ブログ,エンジニア,プログラミング,Ruby on Rails,AI,技術記事",
      og: {
        title: title,
        description: description,
        type: "website",
        image: default_og_image_url
      },
      twitter: {
        title: title,
        description: description,
        image: default_og_image_url
      }
    )
  end

  def category_meta_tags(category)
    return blog_top_meta_tags unless category

    title = "#{category.name} | Miyakawa Codes Blog"
    description = category.description.presence ||
                 "#{category.name}に関する記事一覧です。技術情報やプロジェクト進捗をお届けします。"

    # Categoryモデルにkeywordsフィールドがないため、name + デフォルトキーワードを使用
    keywords = "#{category.name},ブログ,技術記事,#{category.name}記事"

    build_meta_tags(
      title: title,
      description: description,
      keywords: keywords,
      og: {
        title: title,
        description: description,
        type: "website",
        image: default_og_image_url
      },
      twitter: {
        title: title,
        description: description,
        image: default_og_image_url
      }
    )
  end

  private

  def build_meta_tags(options = {})
    meta_tags = default_meta_tags.deep_merge(options)

    tags = []
    tags << "\n    <!-- Basic Meta Tags -->"
    tags << content_tag(:meta, nil, charset: "utf-8")
    tags << content_tag(:meta, nil, name: "viewport", content: "width=device-width, initial-scale=1")
    tags << content_tag(:meta, nil, name: "description", content: meta_tags[:description])
    tags << content_tag(:meta, nil, name: "keywords", content: meta_tags[:keywords])

    # Favicon tags
    tags << "\n    <!-- Favicon -->"
    tags << SiteAssetsService.new.favicon_tags

    # OGP tags
    tags << "\n    <!-- Open Graph / Facebook -->"
    tags << content_tag(:meta, nil, property: "og:site_name", content: meta_tags[:og][:site_name])
    tags << content_tag(:meta, nil, property: "og:title", content: meta_tags[:og][:title])
    tags << content_tag(:meta, nil, property: "og:description", content: meta_tags[:og][:description])
    tags << content_tag(:meta, nil, property: "og:type", content: meta_tags[:og][:type])
    tags << content_tag(:meta, nil, property: "og:url", content: meta_tags[:og][:url])
    tags << content_tag(:meta, nil, property: "og:image", content: meta_tags[:og][:image])
    # OGP画像は1200x630で統一
    tags << content_tag(:meta, nil, property: "og:image:width", content: "1200")
    tags << content_tag(:meta, nil, property: "og:image:height", content: "630")
    tags << content_tag(:meta, nil, property: "og:locale", content: meta_tags[:og][:locale])

    # Twitter Card tags
    tags << "\n    <!-- Twitter Card -->"
    tags << content_tag(:meta, nil, name: "twitter:card", content: meta_tags[:twitter][:card])
    tags << content_tag(:meta, nil, name: "twitter:site", content: meta_tags[:twitter][:site])
    tags << content_tag(:meta, nil, name: "twitter:title", content: meta_tags[:twitter][:title])
    tags << content_tag(:meta, nil, name: "twitter:description", content: meta_tags[:twitter][:description])
    tags << content_tag(:meta, nil, name: "twitter:image", content: meta_tags[:twitter][:image])
    tags << content_tag(:meta, nil, name: "twitter:image:width", content: "1200")
    tags << content_tag(:meta, nil, name: "twitter:image:height", content: "630")

    # Ensure all tags are UTF-8 encoded before joining
    tags.map { |tag| tag.to_s.encode("UTF-8", invalid: :replace, undef: :replace) }
        .join("\n    ").html_safe
  end

  def default_meta_tags
    site_title = SiteSetting.site_title.value.presence || "宮川 剛 - シニアエンジニアのポートフォリオ"
    site_description = SiteSetting.site_description.value.presence || "シニアエンジニアの技術発信・ポートフォリオサイト。20年以上の経験を活かしたシステム設計・開発を提供します。"

    {
      site: site_title,
      title: site_title,
      reverse: true,
      separator: "|",
      description: site_description,
      keywords: "エンジニア,システムエンジニア,プロジェクトマネージャ,Ruby on Rails,AI,ChatGPT",
      canonical: @request&.original_url,
      noindex: !Rails.env.production?,
      og: {
        site_name: "宮川 剛 - シニアエンジニアのポートフォリオ",
        title: "宮川 剛 - シニアエンジニアのポートフォリオ",
        description: "シニアエンジニアの技術発信・ポートフォリオサイト。20年以上の経験を活かしたシステム設計・開発を提供します。",
        type: "website",
        url: @request&.original_url,
        image: default_og_image_url,
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        site: "@miyakawa2449",  # TODO: 管理画面から設定可能にする
        title: "宮川 剛 - シニアエンジニアのポートフォリオ",
        description: "シニアエンジニアの技術発信・ポートフォリオサイト。20年以上の経験を活かしたシステム設計・開発を提供します。",
        image: default_og_image_url
      }
    }
  end

  private

  # SiteAssetsServiceへの委譲メソッド
  def safe_url_for(attachment)
    site_assets_service.safe_url_for(attachment)
  end

  def default_og_image_url
    site_assets_service.og_image_url
  end

  def site_assets_service
    @site_assets_service ||= SiteAssetsService.new(@request)
  end

  # ActionViewヘルパーメソッドにアクセスするため
  def content_tag(*args)
    ApplicationController.helpers.content_tag(*args)
  end

  def truncate(*args)
    ApplicationController.helpers.truncate(*args)
  end

  def strip_tags(*args)
    ApplicationController.helpers.strip_tags(*args)
  end
end
