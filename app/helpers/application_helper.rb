require 'redcarpet'
require 'cgi'

module ApplicationHelper
  # カスタムレンダラーをモジュール外で定義
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
    return '' if text.blank?
    
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
    
    markdown_processor.render(text).html_safe
  end
  
  # コードシンタックスハイライト対応版（将来拡張用）
  def markdown_with_highlight(text)
    return '' if text.blank?
    
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
    
    markdown_processor.render(text).html_safe
  end
  
  # 安全なMarkdown処理（エラーハンドリング付き）
  def safe_markdown(text)
    return '' if text.blank?
    
    begin
      markdown(text)
    rescue StandardError => e
      Rails.logger.error "Markdown processing error: #{e.message}"
      simple_format(text)
    end
  end
  
  # Aboutセクションの情報を取得
  def about_section
    @about_section ||= Section.find_by(name: 'about')
  end
  
end
