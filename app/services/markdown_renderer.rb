# frozen_string_literal: true

require "redcarpet"
require "cgi"

# Markdown→安全なHTML変換（S1-7 P3-8でMarkdownHelperから分離）
# - レンダラーはスレッドごとにメモ化し毎回の再生成を避ける（Redcarpetはスレッド間共有不可）
# - OGPカード等のビュー都合のHTML生成はブロックで注入する（サービス→ビューの逆流を解消）
# - 出力は必ず許可リストでサニタイズする。XSS回帰テスト: spec/services/markdown_renderer_spec.rb
class MarkdownRenderer
  RENDERER_OPTIONS = {
    filter_html: false,
    no_images: false,
    no_links: false,
    no_styles: true,
    safe_links_only: true,
    with_toc_data: false,
    hard_wrap: true
  }.freeze

  MARKDOWN_OPTIONS = {
    autolink: true,
    tables: true,
    fenced_code_blocks: true,
    strikethrough: true,
    space_after_headers: true,
    superscript: true,
    underline: true,
    highlight: true,
    quote: true
  }.freeze

  ALLOWED_TAGS = %w[
    h1 h2 h3 h4 h5 h6 p br hr
    strong em u s del ins mark
    ul ol li
    blockquote pre code
    a img
    table thead tbody tr th td
    div span figure figcaption
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    href title target rel
    src alt width height loading
    class
    colspan rowspan
  ].freeze

  # コードブロックに言語クラスを付けるカスタムレンダラー
  class HTMLwithPygments < Redcarpet::Render::HTML
    def block_code(code, language)
      if language.present?
        "<pre class=\"language-#{CGI.escapeHTML(language)} bg-gray-100 p-4 rounded-lg overflow-x-auto\"><code class=\"language-#{CGI.escapeHTML(language)}\">#{CGI.escapeHTML(code)}</code></pre>"
      else
        "<pre class=\"bg-gray-100 p-4 rounded-lg overflow-x-auto\"><code>#{CGI.escapeHTML(code)}</code></pre>"
      end
    end
  end

  class << self
    # 基本のMarkdown変換
    def render(text)
      return "" if text.blank?

      sanitize(plain_processor.render(normalize(text)))
    end

    # コードハイライト（言語クラス付与）対応版
    def render_with_highlight(text)
      return "" if text.blank?

      sanitize(highlight_processor.render(normalize(text)))
    end

    # 単独行URLをカードHTMLに置換する版。
    # カードHTMLの生成はビュー層からブロックで注入する（nilならプレーンリンク）
    def render_with_ogp_cards(text)
      return "" if text.blank?

      normalized = normalize(text)
      card_urls = detect_isolated_urls(normalized)
      html = sanitize(highlight_processor.render(normalized))

      card_urls.each do |url|
        card_html = (yield(url) if block_given?)
        card_html = fallback_link(url) if card_html.blank?

        escaped_url = Regexp.escape(url)
        # autolinkでaタグになった場合と、そのまま残った場合の両方を置換する
        html = html.gsub(/<p><a href="#{escaped_url}">#{escaped_url}<\/a><\/p>/, card_html.to_s)
        html = html.gsub(/<p>#{escaped_url}<\/p>/, card_html.to_s)
      end

      html.html_safe
    end

    private

    def normalize(text)
      # エスケープされた改行文字を実際の改行に変換
      text.gsub('\\n', "\n")
    end

    # 前後が空行（または先頭/末尾）の単独行URLを抽出する
    def detect_isolated_urls(text)
      url_pattern = /^https?:\/\/[^\s]+$/
      lines = text.lines

      lines.each_with_index.filter_map do |line, index|
        stripped = line.strip
        next unless stripped.match?(url_pattern)

        prev_line = index > 0 ? lines[index - 1]&.strip : ""
        next_line = lines[index + 1]&.strip || ""
        if (prev_line.empty? || index == 0) && (next_line.empty? || index == lines.length - 1)
          stripped
        end
      end.uniq
    end

    def fallback_link(url)
      escaped = ERB::Util.html_escape(url)
      %(<p><a href="#{escaped}" target="_blank" rel="noopener noreferrer">#{escaped}</a></p>)
    end

    def sanitize(html)
      # 許可リストでサニタイズ済みのHTMLなので html_safe を付けて返す
      Rails::HTML5::SafeListSanitizer.new.sanitize(
        html,
        tags: ALLOWED_TAGS,
        attributes: ALLOWED_ATTRIBUTES
      ).html_safe
    end

    def plain_processor
      Thread.current[:markdown_renderer_plain] ||=
        Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(RENDERER_OPTIONS), MARKDOWN_OPTIONS)
    end

    def highlight_processor
      Thread.current[:markdown_renderer_highlight] ||=
        Redcarpet::Markdown.new(HTMLwithPygments.new(RENDERER_OPTIONS), MARKDOWN_OPTIONS)
    end
  end
end
