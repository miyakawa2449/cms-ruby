# frozen_string_literal: true

require "rails_helper"

# S1-7 P3-8: MarkdownHelperから変換ロジックを分離。
# 公開ページに出るHTMLの安全性を担保するため、XSS回帰テストを必ず維持すること
RSpec.describe MarkdownRenderer do
  describe ".render" do
    it "Markdownを HTML に変換する" do
      html = described_class.render("# 見出し\n\n**強調**")

      expect(html).to include("<h1>見出し</h1>")
      expect(html).to include("<strong>強調</strong>")
    end

    it "空入力は空文字を返す" do
      expect(described_class.render(nil)).to eq("")
      expect(described_class.render("")).to eq("")
    end

    it "html_safeな文字列を返す（ビューで二重エスケープされない）" do
      expect(described_class.render("text")).to be_html_safe
    end

    it "エスケープされた改行文字を実際の改行として扱う" do
      html = described_class.render('1行目\n\n2行目')

      expect(html).to include("1行目")
      expect(html).to include("2行目")
    end
  end

  describe "XSS対策（回帰テスト・削除禁止）" do
    it "scriptタグを除去する" do
      html = described_class.render("こんにちは <script>alert('xss')</script>")

      expect(html).not_to include("<script")
      expect(html).not_to include("alert('xss')")
    end

    it "イベントハンドラ属性を除去する" do
      html = described_class.render('<img src="x.png" onerror="alert(1)">')

      expect(html).not_to include("onerror")
    end

    it "javascript:リンクを無効化する（safe_links_onlyによりリンク化されず平文になる）" do
      html = described_class.render("[click](javascript:alert(1))")

      expect(html).not_to include('href="javascript:')
      expect(html).not_to include("<a")
    end

    it "style属性・styleタグを除去する" do
      html = described_class.render('<div style="position:fixed">x</div><style>body{}</style>')

      expect(html).not_to include("style=")
      expect(html).not_to include("<style")
    end

    it "iframeを除去する" do
      html = described_class.render('<iframe src="https://evil.example.com"></iframe>')

      expect(html).not_to include("<iframe")
    end

    it "render_with_ogp_cardsでも同じサニタイズが効く" do
      html = described_class.render_with_ogp_cards("<script>alert('xss')</script>")

      expect(html).not_to include("<script")
    end
  end

  describe ".render_with_highlight" do
    it "コードブロックに言語クラスを付与しコードをエスケープする" do
      html = described_class.render_with_highlight("```ruby\nputs '<b>'\n```")

      expect(html).to include("language-ruby")
      expect(html).to include("&lt;b&gt;")
    end
  end

  describe ".render_with_ogp_cards" do
    it "単独行URLをブロックが返すカードHTMLに置換する" do
      text = "前の段落\n\nhttps://example.com/page\n\n次の段落"

      html = described_class.render_with_ogp_cards(text) { |url| %(<div class="ogp-card">#{url}</div>) }

      expect(html).to include('<div class="ogp-card">https://example.com/page</div>')
      expect(html).not_to include('<p><a href="https://example.com/page"')
    end

    it "ブロックがnilを返したらプレーンリンクにフォールバックする" do
      html = described_class.render_with_ogp_cards("https://example.com/page") { |_url| nil }

      expect(html).to include('rel="noopener noreferrer"')
      expect(html).to include("https://example.com/page")
    end

    it "文中のURLはカード化しない" do
      text = "本文中の https://example.com/page はリンクのまま"

      html = described_class.render_with_ogp_cards(text) { |url| "<div>CARD</div>" }

      expect(html).not_to include("CARD")
    end
  end
end
