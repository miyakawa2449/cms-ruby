module SearchHelper
  # キーワードをハイライトする
  # @param text [String] ハイライト対象のテキスト
  # @param query [String] 検索キーワード（スペース区切りで複数可）
  # @return [String] ハイライト済みのHTML safe文字列
  def highlight_keywords(text, query)
    return '' if text.nil?
    return text if query.blank?

    # テキストをHTMLエスケープ
    escaped_text = ERB::Util.html_escape(text.to_s)

    # キーワードを分割（空白で区切る）
    keywords = query.to_s.strip.split(/\s+/).reject(&:blank?)
    return escaped_text if keywords.empty?

    # 各キーワードをハイライト
    keywords.each do |keyword|
      # 正規表現の特殊文字をエスケープ
      escaped_keyword = Regexp.escape(keyword)
      # 大文字小文字を区別せずにマッチ
      escaped_text = escaped_text.gsub(
        /#{escaped_keyword}/i,
        '<mark class="bg-yellow-200 px-1 rounded">\0</mark>'
      )
    end

    escaped_text.html_safe
  end

  # キーワード周辺のテキストを抽出してハイライトする
  # @param text [String] 対象のテキスト
  # @param query [String] 検索キーワード
  # @param length [Integer] 抽出する最大文字数
  # @return [String] 切り詰め・ハイライト済みのHTML safe文字列
  def truncate_with_highlight(text, query, length: 200)
    return '' if text.nil?
    text_str = text.to_s

    if query.present?
      # 最初のキーワードの位置を見つける
      first_keyword = query.to_s.strip.split(/\s+/).first
      keyword_pos = text_str.downcase.index(first_keyword.to_s.downcase) if first_keyword.present?

      if keyword_pos
        # キーワード周辺のテキストを抽出
        start_pos = [keyword_pos - 50, 0].max
        truncated = text_str[start_pos, length]

        # 前後に省略記号を追加
        prefix = start_pos > 0 ? '...' : ''
        suffix = (start_pos + length) < text_str.length ? '...' : ''

        return "#{prefix}#{highlight_keywords(truncated, query)}#{suffix}".html_safe
      end
    end

    # キーワードが見つからない場合は先頭から切り詰め
    truncated = truncate(text_str, length: length, omission: '...')
    highlight_keywords(truncated, query)
  end
end
