# frozen_string_literal: true

module SeoHelper
  # SEOメタタグを一括で設定
  def set_meta_tags(options = {})
    @meta_tags ||= {}
    @meta_tags.merge!(options)
  end

  # ページタイトルを設定
  def page_title(title, options = {})
    separator = options[:separator] || ' | '
    base_title = options[:base_title] || 'Miyakawa Codes'
    
    full_title = title.present? ? "#{title}#{separator}#{base_title}" : base_title
    content_for :title, full_title
  end

  # メタディスクリプションを設定
  def meta_description(description)
    content_for :description, truncate(description, length: 155)
  end

  # メタキーワードを設定
  def meta_keywords(keywords)
    keywords_string = keywords.is_a?(Array) ? keywords.join(',') : keywords
    content_for :keywords, keywords_string
  end

  # Open Graphタグを設定
  def set_og_tags(options = {})
    content_for :og_title, options[:title] if options[:title]
    content_for :og_description, options[:description] if options[:description]
    content_for :og_image, options[:image] if options[:image]
    content_for :og_type, options[:type] || 'website'
  end

  # Twitterカードを設定
  def set_twitter_card(options = {})
    content_for :twitter_card, options[:card] || 'summary_large_image'
    content_for :twitter_title, options[:title] if options[:title]
    content_for :twitter_description, options[:description] if options[:description]
    content_for :twitter_image, options[:image] if options[:image]
  end

  # 構造化データ（JSON-LD）を追加
  def add_structured_data(data)
    content_for :additional_structured_data do
      tag.script(data.to_json.html_safe, type: 'application/ld+json')
    end
  end

  # パンくずリスト用の構造化データを生成
  def breadcrumb_structured_data(items)
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": items.each_with_index.map do |(name, url), index|
        {
          "@type": "ListItem",
          "position": index + 1,
          "name": name,
          "item": url ? full_url(url) : nil
        }.compact
      end
    }
  end

  # 記事用の構造化データを生成
  def article_structured_data(article)
    {
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      "headline": article[:title],
      "description": article[:description],
      "image": article[:image] ? full_url(article[:image]) : nil,
      "author": {
        "@type": "Person",
        "name": article[:author] || "宮川 剛",
        "url": root_url
      },
      "publisher": {
        "@type": "Organization",
        "name": "Miyakawa Codes",
        "logo": {
          "@type": "ImageObject",
          "url": asset_url('logo.png')
        }
      },
      "datePublished": article[:published_at]&.iso8601,
      "dateModified": article[:updated_at]&.iso8601,
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": article[:url] || request.original_url
      },
      "keywords": article[:keywords]&.join(','),
      "articleSection": article[:category],
      "wordCount": article[:word_count],
      "inLanguage": "ja-JP"
    }.compact
  end

  # FAQ用の構造化データを生成
  def faq_structured_data(faqs)
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      "mainEntity": faqs.map do |faq|
        {
          "@type": "Question",
          "name": faq[:question],
          "acceptedAnswer": {
            "@type": "Answer",
            "text": faq[:answer]
          }
        }
      end
    }
  end

  # HowTo用の構造化データを生成
  def how_to_structured_data(how_to)
    {
      "@context": "https://schema.org",
      "@type": "HowTo",
      "name": how_to[:name],
      "description": how_to[:description],
      "image": how_to[:image] ? full_url(how_to[:image]) : nil,
      "totalTime": how_to[:total_time],
      "estimatedCost": how_to[:cost] ? {
        "@type": "MonetaryAmount",
        "currency": "JPY",
        "value": how_to[:cost]
      } : nil,
      "supply": how_to[:supplies]&.map { |s| { "@type": "HowToSupply", "name": s } },
      "tool": how_to[:tools]&.map { |t| { "@type": "HowToTool", "name": t } },
      "step": how_to[:steps]&.map.with_index do |step, index|
        {
          "@type": "HowToStep",
          "name": step[:name],
          "text": step[:text],
          "image": step[:image] ? full_url(step[:image]) : nil,
          "url": step[:url],
          "position": index + 1
        }.compact
      end
    }.compact
  end

  # 画像の遅延読み込み属性を追加
  def lazy_image_tag(source, options = {})
    default_options = {
      loading: 'lazy',
      decoding: 'async'
    }
    
    # Core Web Vitals対策：サイズを明示的に指定
    if options[:width] && options[:height]
      default_options[:width] = options[:width]
      default_options[:height] = options[:height]
    end
    
    image_tag(source, default_options.merge(options))
  end

  # レスポンシブ画像タグを生成
  def responsive_image_tag(source, options = {})
    srcset = options.delete(:srcset) || generate_srcset(source)
    sizes = options.delete(:sizes) || '(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw'
    
    lazy_image_tag(source, options.merge(srcset: srcset, sizes: sizes))
  end

  private

  def full_url(path)
    return path if path =~ /\Ahttps?:\/\//
    URI.join(root_url, path).to_s
  end

  def generate_srcset(source)
    # 実際の実装では、画像処理ライブラリを使って異なるサイズを生成
    base_path = source.sub(/\.\w+$/, '')
    ext = source.match(/\.(\w+)$/)[1]
    
    [
      "#{base_path}_400w.#{ext} 400w",
      "#{base_path}_800w.#{ext} 800w",
      "#{base_path}_1200w.#{ext} 1200w",
      "#{base_path}_1600w.#{ext} 1600w"
    ].join(', ')
  end
end