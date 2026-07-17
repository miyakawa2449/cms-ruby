# frozen_string_literal: true

# Markdown表示用の薄いヘルパー。変換本体はMarkdownRenderer（S1-7 P3-8で分離）
module MarkdownHelper
  # Markdownテキストを安全なHTMLに変換
  def markdown(text)
    MarkdownRenderer.render(text)
  end

  # コードシンタックスハイライト対応版
  def markdown_with_highlight(text)
    MarkdownRenderer.render_with_highlight(text)
  end

  # 安全なMarkdown処理（エラーハンドリング付き）
  def safe_markdown(text)
    return "" if text.blank?

    MarkdownRenderer.render(text)
  rescue StandardError => e
    Rails.logger.error "Markdown processing error: #{e.message}"
    simple_format(text)
  end

  # OGPカード対応Markdown処理（単独行のURLをOGPカードに変換）
  # カードのHTML生成はビュー層（このヘルパー）が担当する
  def markdown_with_ogp_cards(text)
    MarkdownRenderer.render_with_ogp_cards(text) { |url| ogp_card_html(url) }
  end

  private

  # OGP取得に成功したらカードパーシャルを描画、失敗はnil（レンダラー側でリンクにフォールバック）
  # 取得結果はOgpFetcherService内でキャッシュされる（キャッシュミス時のみ同期fetch）
  def ogp_card_html(url)
    result = OgpFetcherService.new(url).fetch
    return nil unless result.success?

    render(partial: "shared/ogp_card", locals: { ogp_data: result.data })
  rescue StandardError => e
    Rails.logger.error "OGP card render error: #{e.message}"
    nil
  end
end
