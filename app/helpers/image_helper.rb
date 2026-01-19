# frozen_string_literal: true

# 画像表示の最適化ヘルパー
module ImageHelper
  # 遅延読み込み対応の画像タグを生成
  #
  # @param source [String, ActiveStorage::Attached] 画像ソース
  # @param options [Hash] image_tagに渡すオプション
  # @return [String] imgタグのHTML
  #
  # @example 基本的な使用方法
  #   lazy_image_tag("example.jpg", alt: "Example")
  #
  # @example ActiveStorageの画像
  #   lazy_image_tag(article.thumbnail, alt: article.title)
  #
  def lazy_image_tag(source, options = {})
    # デフォルトでlazy loadingとasync decodingを有効化
    options[:loading] ||= "lazy"
    options[:decoding] ||= "async"

    image_tag(source, options)
  end

  # ActiveStorage添付ファイル用の遅延読み込み画像タグ
  #
  # @param attachment [ActiveStorage::Attached::One] 添付ファイル
  # @param variant [Hash] 画像バリアントオプション（リサイズ等）
  # @param options [Hash] image_tagに渡すオプション
  # @return [String] imgタグのHTML、添付ファイルがない場合はnil
  #
  # @example バリアント指定
  #   lazy_attachment_image(article.thumbnail, { resize_to_limit: [300, 200] }, alt: article.title)
  #
  def lazy_attachment_image(attachment, variant = nil, options = {})
    return nil unless attachment&.attached?

    source = variant ? attachment.variant(variant) : attachment
    lazy_image_tag(source, options)
  end

  # プレースホルダー付きの遅延読み込み画像タグ
  #
  # @param source [String, ActiveStorage::Attached] 画像ソース
  # @param placeholder [String] プレースホルダー画像のURL（オプション）
  # @param options [Hash] image_tagに渡すオプション
  # @return [String] imgタグのHTML
  #
  def lazy_image_with_placeholder(source, placeholder: nil, **options)
    options[:loading] ||= "lazy"
    options[:decoding] ||= "async"

    # data-srcにはnoscript対応のために実際のURLを保持
    if placeholder.present?
      options[:src] = placeholder
      options[:data] ||= {}
      options[:data][:src] = url_for(source)
    end

    image_tag(placeholder.presence || source, options)
  end
end
