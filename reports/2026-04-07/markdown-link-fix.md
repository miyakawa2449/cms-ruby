# Markdownリンクhref属性脱落問題の修正レポート

## 📅 作成日: 2026-04-07

## 🐛 問題の概要

### 症状
- ブログ記事のMarkdownエディタで設定したリンク（`[テキスト](URL)`）が、公開側で正常に機能しない
- `<a>`タグは生成されるが、`href`属性が完全に脱落している
- 例: `<a>Googleへのリンク</a>` （`href`属性なし）

### 影響範囲
- 本番環境で発生
- 全てのブログ記事のリンクが機能していない状態

---

## 🔍 原因分析

### 根本原因
Rails 8.1.1では、`ActionController::Base.helpers.sanitize`の`attributes`オプションの形式が変更されていた。

**旧形式（ハッシュ形式）**:
```ruby
def allowed_attributes
  {
    "a" => %w[href title target rel],
    "img" => %w[src alt title width height loading],
    # ...
  }
end
```

**新形式（配列形式）**:
```ruby
def allowed_attributes
  %w[
    href title target rel
    src alt width height loading
    # ...
  ]
end
```

### 問題の発生箇所
`app/helpers/markdown_helper.rb`の`sanitize_html`メソッドで、ハッシュ形式の`allowed_attributes`を使用していたため、Rails 8.1.1のサニタイザーが属性を正しく認識できず、全ての属性が削除されていた。

---

## ✅ 修正内容

### 1. `allowed_attributes`メソッドの修正

**修正前**:
```ruby
def allowed_attributes
  {
    "a" => %w[href title target rel],
    "img" => %w[src alt title width height loading],
    "code" => %w[class],
    "pre" => %w[class],
    "table" => %w[class],
    "th" => %w[colspan rowspan],
    "td" => %w[colspan rowspan],
    "div" => %w[class],
    "span" => %w[class],
    "figure" => %w[class],
    "figcaption" => %w[class]
  }
end
```

**修正後**:
```ruby
def allowed_attributes
  %w[
    href title target rel
    src alt width height loading
    class
    colspan rowspan
  ]
end
```

### 2. `sanitize_html`メソッドの修正

**修正前**:
```ruby
def sanitize_html(html)
  ActionController::Base.helpers.sanitize(
    html,
    tags: allowed_tags,
    attributes: allowed_attributes
  )
end
```

**修正後**:
```ruby
def sanitize_html(html)
  Rails::HTML5::SafeListSanitizer.new.sanitize(
    html,
    tags: allowed_tags,
    attributes: allowed_attributes
  )
end
```

---

## 🧪 検証結果

### テスト実行結果

**Input Validation テスト**: 全て通過 ✅
- `removes script tags` ✅
- `allows safe links` ✅ （重要）
- `removes dangerous attributes` ✅
- `strips javascript links` ✅

**Markdown レンダリングテスト**:
```ruby
content = '[Googleへのリンク](https://www.google.com)

これは通常のテキストです。

[GitHubへのリンク](https://github.com)'

html = markdown(content)
```

**結果**:
```html
<p><a href="https://www.google.com">Googleへのリンク</a></p>

<p>これは通常のテキストです。</p>

<p><a href="https://github.com">GitHubへのリンク</a></p>
```

✅ `href`属性が正しくレンダリングされている

---

## 🚀 本番環境への反映手順

### 1. 修正ファイルの確認
- `app/helpers/markdown_helper.rb`

### 2. デプロイ手順
```bash
# 1. 変更をコミット
git add app/helpers/markdown_helper.rb
git commit -m "Fix: Markdown link href attribute sanitization for Rails 8.1.1"

# 2. 本番環境にデプロイ
./deploy.sh

# 3. 本番環境で動作確認
# - ブログ記事のリンクをクリックして、正しく遷移することを確認
# - 複数の記事で確認
```

### 3. 動作確認項目
- [ ] ブログ記事一覧ページの表示
- [ ] ブログ記事詳細ページの表示
- [ ] 記事内のリンクをクリックして、正しく遷移することを確認
- [ ] 外部リンク（`target="_blank"`）が新しいタブで開くことを確認
- [ ] 画像の表示（`src`属性が正しく機能）
- [ ] コードブロックのシンタックスハイライト（`class`属性が正しく機能）

---

## 📝 注意事項

### セキュリティ
- XSS対策は維持されている（`<script>`タグは削除される）
- `javascript:`プロトコルのリンクは削除される
- 危険な属性（`onerror`等）は削除される

### 互換性
- Rails 8.1.1の新しいサニタイザー形式に対応
- 既存の機能（OGPカード、画像キャプション等）は影響を受けない

---

## 🔄 今後の対応

### 推奨事項
1. **本番環境デプロイ**: 修正を本番環境に反映
2. **動作確認**: 全てのブログ記事のリンクが正常に機能することを確認
3. **監視**: デプロイ後、エラーログを監視

### 将来の改善
- Rails 8.1.1のサニタイザー仕様変更を文書化
- 自動テストの追加（リンク機能の回帰テスト）

---

**📝 作成者**: Kiro  
**📅 作成日**: 2026-04-07  
**🔧 修正ファイル**: `app/helpers/markdown_helper.rb`  
**✅ テスト結果**: 全て通過  
**🚀 本番反映**: 準備完了
