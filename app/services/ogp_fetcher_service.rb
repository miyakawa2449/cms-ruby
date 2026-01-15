# frozen_string_literal: true

require "open-uri"
require "nokogiri"
require "uri"

# 外部URLからOGP情報を取得するサービス
class OgpFetcherService
  CACHE_EXPIRY = 1.day
  TIMEOUT = 5
  MAX_DESCRIPTION_LENGTH = 200

  Result = Struct.new(:success?, :data, :error, keyword_init: true)
  OgpData = Struct.new(:url, :title, :description, :image, :site_name, :favicon, keyword_init: true)

  def initialize(url)
    @url = url
    @uri = URI.parse(url)
  end

  def fetch
    cached = Rails.cache.read(cache_key)
    return Result.new(success?: true, data: cached) if cached

    html = fetch_html
    return Result.new(success?: false, error: "Failed to fetch URL") unless html

    doc = Nokogiri::HTML(html)
    ogp_data = extract_ogp(doc)

    Rails.cache.write(cache_key, ogp_data, expires_in: CACHE_EXPIRY)
    Result.new(success?: true, data: ogp_data)
  rescue StandardError => e
    Rails.logger.error "OGP fetch error for #{@url}: #{e.message}"
    Result.new(success?: false, error: e.message)
  end

  private

  def cache_key
    "ogp:#{Digest::MD5.hexdigest(@url)}"
  end

  def fetch_html
    URI.open(
      @url,
      "User-Agent" => "Mozilla/5.0 (compatible; OGPBot/1.0)",
      read_timeout: TIMEOUT,
      open_timeout: TIMEOUT
    ).read
  rescue OpenURI::HTTPError, Timeout::Error, SocketError => e
    Rails.logger.warn "Failed to fetch #{@url}: #{e.message}"
    nil
  end

  def extract_ogp(doc)
    OgpData.new(
      url: @url,
      title: extract_title(doc),
      description: extract_description(doc),
      image: extract_image(doc),
      site_name: extract_site_name(doc),
      favicon: extract_favicon(doc)
    )
  end

  def extract_title(doc)
    og_title = doc.at('meta[property="og:title"]')&.[]("content")
    twitter_title = doc.at('meta[name="twitter:title"]')&.[]("content")
    html_title = doc.at("title")&.text

    (og_title || twitter_title || html_title || @uri.host).to_s.strip.truncate(100)
  end

  def extract_description(doc)
    og_desc = doc.at('meta[property="og:description"]')&.[]("content")
    twitter_desc = doc.at('meta[name="twitter:description"]')&.[]("content")
    meta_desc = doc.at('meta[name="description"]')&.[]("content")

    desc = (og_desc || twitter_desc || meta_desc || "").to_s.strip
    desc.truncate(MAX_DESCRIPTION_LENGTH)
  end

  def extract_image(doc)
    og_image = doc.at('meta[property="og:image"]')&.[]("content")
    twitter_image = doc.at('meta[name="twitter:image"]')&.[]("content")

    image_url = og_image || twitter_image
    return nil unless image_url.present?

    absolutize_url(image_url)
  end

  def extract_site_name(doc)
    og_site = doc.at('meta[property="og:site_name"]')&.[]("content")
    return og_site if og_site.present?

    # サイト名がない場合はドメイン名を使用
    @uri.host.sub(/^www\./, "")
  end

  def extract_favicon(doc)
    # 複数のfaviconパターンを試行
    favicon_selectors = [
      'link[rel="icon"]',
      'link[rel="shortcut icon"]',
      'link[rel="apple-touch-icon"]',
      'link[rel="apple-touch-icon-precomposed"]'
    ]

    favicon_selectors.each do |selector|
      link = doc.at(selector)
      if link && link["href"].present?
        return absolutize_url(link["href"])
      end
    end

    # デフォルトのfavicon.icoを試行
    "#{@uri.scheme}://#{@uri.host}/favicon.ico"
  end

  def absolutize_url(relative_url)
    return relative_url if relative_url.start_with?("http://", "https://")
    return "https:#{relative_url}" if relative_url.start_with?("//")

    base_url = "#{@uri.scheme}://#{@uri.host}"
    if relative_url.start_with?("/")
      "#{base_url}#{relative_url}"
    else
      "#{base_url}/#{relative_url}"
    end
  end
end
