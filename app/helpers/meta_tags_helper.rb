module MetaTagsHelper
  def default_meta_tags
    {
      site: '宮川 剛 - シニアエンジニアのポートフォリオ',
      title: '宮川 剛 - シニアエンジニアのポートフォリオ',
      reverse: true,
      separator: '|',
      description: 'シニアエンジニアの技術発信・ポートフォリオサイト。20年以上の経験を活かしたシステム設計・開発を提供します。',
      keywords: 'エンジニア,システムエンジニア,プロジェクトマネージャ,Ruby on Rails,AI,ChatGPT',
      canonical: request.original_url,
      noindex: !Rails.env.production?,
      icon: [
        { href: '/favicon.ico' }
      ],
      og: {
        site_name: '宮川 剛 - シニアエンジニアのポートフォリオ',
        title: '宮川 剛 - シニアエンジニアのポートフォリオ',
        description: 'シニアエンジニアの技術発信・ポートフォリオサイト。20年以上の経験を活かしたシステム設計・開発を提供します。',
        type: 'website',
        url: request.original_url,
        image: default_og_image_url,
        locale: 'ja_JP'
      },
      twitter: {
        card: 'summary_large_image',
        site: '@miyakawa_dev',
        title: '宮川 剛 - シニアエンジニアのポートフォリオ',
        description: 'シニアエンジニアの技術発信・ポートフォリオサイト。20年以上の経験を活かしたシステム設計・開発を提供します。',
        image: default_og_image_url
      }
    }
  end

  def page_meta_tags(options = {})
    # optionsがnilまたはHashでない場合は空のHashを使用
    options = {} unless options.is_a?(Hash)
    meta_tags = default_meta_tags.deep_merge(options)
    
    # 動的なメタタグ設定
    content_tag(:meta, nil, charset: 'utf-8') +
    content_tag(:meta, nil, name: 'viewport', content: 'width=device-width, initial-scale=1') +
    content_tag(:meta, nil, name: 'description', content: meta_tags[:description]) +
    content_tag(:meta, nil, name: 'keywords', content: meta_tags[:keywords]) +
    
    # OGP tags
    content_tag(:meta, nil, property: 'og:site_name', content: meta_tags[:og][:site_name]) +
    content_tag(:meta, nil, property: 'og:title', content: meta_tags[:og][:title]) +
    content_tag(:meta, nil, property: 'og:description', content: meta_tags[:og][:description]) +
    content_tag(:meta, nil, property: 'og:type', content: meta_tags[:og][:type]) +
    content_tag(:meta, nil, property: 'og:url', content: meta_tags[:og][:url]) +
    content_tag(:meta, nil, property: 'og:image', content: meta_tags[:og][:image]) +
    content_tag(:meta, nil, property: 'og:locale', content: meta_tags[:og][:locale]) +
    
    # Twitter Card tags
    content_tag(:meta, nil, name: 'twitter:card', content: meta_tags[:twitter][:card]) +
    content_tag(:meta, nil, name: 'twitter:site', content: meta_tags[:twitter][:site]) +
    content_tag(:meta, nil, name: 'twitter:title', content: meta_tags[:twitter][:title]) +
    content_tag(:meta, nil, name: 'twitter:description', content: meta_tags[:twitter][:description]) +
    content_tag(:meta, nil, name: 'twitter:image', content: meta_tags[:twitter][:image])
  end

  def article_meta_tags(article)
    description = article.meta_description.presence || article.excerpt.presence || truncate(strip_tags(article.content), length: 160)
    keywords = article.meta_keywords.presence || article.tags.pluck(:name).join(',')
    
    og_title = article.og_title.presence || article.title
    og_description = article.og_description.presence || description
    og_image = article.thumbnail_image.attached? ? rails_blob_url(article.thumbnail_image) : default_og_image_url
    
    page_meta_tags(
      title: article.title,
      description: description,
      keywords: keywords,
      og: {
        title: og_title,
        description: og_description,
        type: 'article',
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

  def my_story_meta_tags(title = 'My Story - 30年間のエンジニア人生', description = 'パソコン講師からSE/PMを経て、50代でAIエンジニアへ。30年間の技術者としての成長と挑戦の軌跡。')
    page_meta_tags(
      title: title,
      description: description,
      keywords: 'エンジニアキャリア,SE,PM,AIエンジニア,プログラミング学習,キャリアチェンジ',
      og: {
        title: "#{title} | 宮川 剛",
        description: description,
        type: 'article',
        image: default_og_image_url # 後でMy Story専用画像に変更可能
      },
      twitter: {
        title: "#{title} | 宮川 剛",
        description: description,
        image: default_og_image_url
      }
    )
  end

  private

  def default_og_image_url
    # デフォルトのOGP画像URL
    # 後でActive Storageやアセットパイプラインから設定
    "#{request.base_url}/og-default.jpg"
  end
end