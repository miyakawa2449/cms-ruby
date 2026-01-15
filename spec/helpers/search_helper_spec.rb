require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  describe '#highlight_keywords' do
    context '正常系' do
      it 'キーワードをハイライトする' do
        text = 'Railsは強力なフレームワークです'
        query = 'Rails'

        result = helper.highlight_keywords(text, query)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">Rails</mark>')
      end

      it '大文字小文字を区別せずにハイライトする' do
        text = 'Railsは強力なフレームワークです'
        query = 'rails'

        result = helper.highlight_keywords(text, query)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">Rails</mark>')
      end

      it '複数のキーワードをハイライトする' do
        text = 'RubyとRailsを使ったWeb開発'
        query = 'Ruby Rails'

        result = helper.highlight_keywords(text, query)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">Ruby</mark>')
        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">Rails</mark>')
      end

      it 'キーワードが複数回出現する場合、すべてハイライトする' do
        text = 'RailsでRailsアプリを作る'
        query = 'Rails'

        result = helper.highlight_keywords(text, query)

        expect(result.scan('<mark class="bg-yellow-200 px-1 rounded">Rails</mark>').count).to eq(2)
      end
    end

    context '異常系' do
      it 'クエリが空の場合、元のテキストを返す' do
        text = 'Railsは強力なフレームワークです'

        result = helper.highlight_keywords(text, '')

        expect(result).to eq(text)
      end

      it 'クエリがnilの場合、元のテキストを返す' do
        text = 'Railsは強力なフレームワークです'

        result = helper.highlight_keywords(text, nil)

        expect(result).to eq(text)
      end

      it 'テキストが空の場合、空文字を返す' do
        result = helper.highlight_keywords('', 'Rails')

        expect(result).to eq('')
      end

      it 'テキストがnilの場合、空文字を返す' do
        result = helper.highlight_keywords(nil, 'Rails')

        expect(result).to eq('')
      end
    end

    context 'セキュリティ' do
      it 'XSS攻撃を防ぐ（テキスト内のHTMLをエスケープ）' do
        text = '<script>alert("XSS")</script>'
        query = 'script'

        result = helper.highlight_keywords(text, query)

        expect(result).not_to include('<script>')
        expect(result).to include('&lt;')
        expect(result).to include('&gt;')
      end

      it 'XSS攻撃を防ぐ（クエリ内のHTMLをエスケープ）' do
        text = 'テスト文字列'
        query = '<script>'

        result = helper.highlight_keywords(text, query)

        expect(result).not_to include('<script>')
      end

      it 'キーワードハイライトでXSS攻撃を防ぐ' do
        text = '<script>alert("XSS")</script>'
        result = helper.highlight_keywords(text, 'script')
        expect(result).not_to include('<script>')
      end
    end

    context 'エッジケース' do
      it '正規表現の特殊文字を含むキーワードをハイライトする' do
        text = '100%達成しました'
        query = '100%'

        result = helper.highlight_keywords(text, query)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">100%</mark>')
      end

      it 'SQLワイルドカード（%）を含むキーワードでハイライトできる' do
        text = '100%達成'
        query = '100%'

        result = helper.highlight_keywords(text, query)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">100%</mark>')
      end

      it '括弧を含むキーワードをハイライトする' do
        text = 'メソッド(引数)を呼び出す'
        query = '(引数)'

        result = helper.highlight_keywords(text, query)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">(引数)</mark>')
      end

      it '前後の空白を含むクエリは空白を無視してハイライトする' do
        text = 'Railsは強力なフレームワークです'
        query = '  Rails  '

        result = helper.highlight_keywords(text, query)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">Rails</mark>')
      end
    end
  end

  describe '#truncate_with_highlight' do
    context '正常系' do
      it 'キーワード周辺のテキストを抽出してハイライトする' do
        text = 'これは非常に長いテキストです。' * 10 + 'Railsは素晴らしい。' + 'これも長いテキストです。' * 10
        query = 'Rails'

        result = helper.truncate_with_highlight(text, query, length: 100)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">Rails</mark>')
        expect(result.length).to be <= 250  # マークアップを含むので余裕を持たせる
      end

      it 'キーワードがない場合、先頭から切り詰める' do
        text = 'これは非常に長いテキストです。' * 10
        query = '存在しないキーワード'

        result = helper.truncate_with_highlight(text, query, length: 50)

        expect(result.length).to be <= 60  # 省略記号を含む
      end
    end

    context '異常系' do
      it 'クエリが空の場合、先頭から切り詰める' do
        text = 'これは長いテキストです。' * 10

        result = helper.truncate_with_highlight(text, '', length: 50)

        expect(result.length).to be <= 60
      end

      it 'テキストが短い場合、そのまま返す' do
        text = '短いテキスト'
        query = 'テキスト'

        result = helper.truncate_with_highlight(text, query, length: 200)

        expect(result).to include('<mark class="bg-yellow-200 px-1 rounded">テキスト</mark>')
      end
    end
  end
end
