require "redcarpet"
require "cgi"

module MarkdownHelper
  include ActionView::Helpers::SanitizeHelper
  # カスタムレンダラー
  class HTMLwithPygments < Redcarpet::Render::HTML
    def block_code(code, language)
      if language.present?
        # 言語が指定されている場合
        "<pre class=\"language-#{CGI.escapeHTML(language)} bg-gray-100 p-4 rounded-lg overflow-x-auto\"><code class=\"language-#{CGI.escapeHTML(language)}\">#{CGI.escapeHTML(code)}</code></pre>"
      else
        # 言語が指定されていない場合
        "<pre class=\"bg-gray-100 p-4 rounded-lg overflow-x-auto\"><code>#{CGI.escapeHTML(code)}</code></pre>"
      end
    end
  end

  # Markdownテキストを安全なHTMLに変換
  def markdown(text)
    return "" if text.blank?

    # エスケープされた改行文字を実際の改行に変換
    text = text.gsub('\\n', "\n")

    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      no_images: false,
      no_links: false,
      no_styles: true,
      safe_links_only: true,
      with_toc_data: false,
      hard_wrap: true
    )

    markdown_processor = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      space_after_headers: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true
    )

    sanitize_html(markdown_processor.render(text))
  end

  # コードシンタックスハイライト対応版
  def markdown_with_highlight(text)
    return "" if text.blank?

    # エスケープされた改行文字を実際の改行に変換
    text = text.gsub('\\n', "\n")

    renderer = HTMLwithPygments.new(
      filter_html: false,
      no_images: false,
      no_links: false,
      no_styles: true,
      safe_links_only: true,
      with_toc_data: false,
      hard_wrap: true
    )

    markdown_processor = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      space_after_headers: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true
    )

    sanitize_html(markdown_processor.render(text))
  end

  def sanitize_html(html)
    Rails::HTML5::SafeListSanitizer.new.sanitize(
      html,
      tags: allowed_tags,
      attributes: allowed_attributes
    )
  end

  # 安全なMarkdown処理（エラーハンドリング付き）
  def safe_markdown(text)
    return "" if text.blank?

    begin
      markdown(text)
    rescue StandardError => e
      Rails.logger.error "Markdown processing error: #{e.message}"
      simple_format(text)
    end
  end

  # OGPカード対応Markdown処理
  # 単独行のURLをOGPカードに変換
  def markdown_with_ogp_cards(text)
    return "" if text.blank?

    # エスケープされた改行文字を実際の改行に変換
    text = text.gsub('\\n', "\n")

    # 単独行URLを抽出してOGPカードに変換
    url_pattern = /^(https?:\/\/[^\s]+)$/
    url_cards = {}

    lines = text.lines
    processed_lines = lines.map.with_index do |line, index|
      stripped = line.strip

      # 単独行のURL（前後が空行または先頭/末尾）をチェック
      if stripped.match?(url_pattern)
        prev_line = index > 0 ? lines[index - 1]&.strip : ""
        next_line = lines[index + 1]&.strip || ""

        # 前後が空行、または先頭/末尾の場合のみカード化
        if (prev_line.empty? || index == 0) && (next_line.empty? || index == lines.length - 1)
          # URLをそのまま保持し、後で置換
          url_cards[stripped] = true
          line
        else
          line
        end
      else
        line
      end
    end

    processed_text = processed_lines.join

    # Markdown処理
    renderer = HTMLwithPygments.new(
      filter_html: false,
      no_images: false,
      no_links: false,
      no_styles: true,
      safe_links_only: true,
      with_toc_data: false,
      hard_wrap: true
    )

    markdown_processor = Redcarpet::Markdown.new(renderer, markdown_options)
    html = sanitize_html(markdown_processor.render(processed_text))

    # autolinkされたURLをOGPカードに置換
    url_cards.each_key do |url|
      escaped_url = Regexp.escape(url)
      # autolinkでaタグになった場合
      autolink_pattern = /<p><a href="#{escaped_url}">#{escaped_url}<\/a><\/p>/
      # そのままの場合
      plain_pattern = /<p>#{escaped_url}<\/p>/

      ogp_card_html = render_ogp_card(url)
      html = html.gsub(autolink_pattern, ogp_card_html)
      html = html.gsub(plain_pattern, ogp_card_html)
    end

    html.html_safe
  end

  private

  def render_ogp_card(url)
    result = OgpFetcherService.new(url).fetch

    if result.success?
      ApplicationController.render(
        partial: "shared/ogp_card",
        locals: { ogp_data: result.data }
      )
    else
      # OGP取得失敗時はシンプルなリンクを表示
      %(<p><a href="#{ERB::Util.html_escape(url)}" target="_blank" rel="noopener noreferrer">#{ERB::Util.html_escape(url)}</a></p>)
    end
  rescue StandardError => e
    Rails.logger.error "OGP card render error: #{e.message}"
    %(<p><a href="#{ERB::Util.html_escape(url)}" target="_blank" rel="noopener noreferrer">#{ERB::Util.html_escape(url)}</a></p>)
  end

  def markdown_options
    {
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      space_after_headers: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true
    }
  end

  def allowed_tags
    %w[
      h1 h2 h3 h4 h5 h6 p br hr
      strong em u s del ins mark
      ul ol li
      blockquote pre code
      a img
      table thead tbody tr th td
      div span figure figcaption
    ]
  end

  def allowed_attributes
    %w[
      href title target rel
      src alt width height loading
      class
      colspan rowspan
    ]
  end

  def renderer_options
    {
      filter_html: false,
      no_images: false,
      no_links: false,
      no_styles: true,
      safe_links_only: true,
      with_toc_data: false,
      hard_wrap: true
    }
  end
end
