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
end
