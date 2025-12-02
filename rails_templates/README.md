# Rails用ERBテンプレート集

Figma Makeで作成したReact + Tailwind CSSデザインを、Ruby on Railsで使用できるERBテンプレートに変換したファイル一式です。

## 📦 含まれるファイル

### ✅ 完成済み

- **レイアウト・共通パーツ**
  - `app/views/layouts/application.html.erb` - メインレイアウト
  - `app/views/shared/_header.html.erb` - ヘッダーパーシャル
  - `app/views/shared/_footer.html.erb` - フッターパーシャル

- **ページビュー**
  - `app/views/pages/portfolio.html.erb` - ポートフォリオページ（トップ）
  - `app/views/pages/my_story.html.erb` - My Storyページ

- **ブログビュー** ✨ NEW
  - `app/views/blog/index.html.erb` - ブログトップページ
  - `app/views/blog/category.html.erb` - カテゴリページ
  - `app/views/blog/article.html.erb` - 記事詳細ページ

- **JavaScript** ⚡ NEW
  - `app/javascript/my_story_animations.js` - My Storyスクロールアニメーション
  - `app/javascript/blog_article_scroll.js` - ブログ記事プログレスバー

- **コントローラー**
  - `app/controllers/pages_controller.rb` - ページコントローラー
  - `app/controllers/blog_controller.rb` - ブログコントローラー

- **スタイル**
  - `app/assets/stylesheets/application.tailwind.css` - Tailwind CSSスタイル

- **設定**
  - `config/routes.rb` - ルーティング設定

- **ドキュメント**
  - `README.md` - このファイル
  - `RAILS_SETUP_GUIDE.md` - 詳細セットアップガイド
  - `JAVASCRIPT_SETUP.md` - JavaScript統合ガイド ⚡ NEW

### 📝 すべて完成！

**全15ファイルが作成済みです！** すぐにRailsプロジェクトで使用できます。

## 🚀 クイックスタート

### 1. Tailwind CSSのインストール

```bash
cd your-rails-project
bundle add tailwindcss-rails
rails tailwindcss:install
```

### 2. ファイルのコピー

```bash
# このディレクトリから、あなたのRailsプロジェクトへコピー
cp -r rails_templates/app/* your-rails-project/app/
cp rails_templates/config/routes.rb your-rails-project/config/
```

### 3. ルーティングの確認

`config/routes.rb` を確認・マージしてください。

### 4. 開発サーバー起動

```bash
rails server
```

ブラウザで `http://localhost:3000` にアクセス

## 📚 詳細ドキュメント

詳しいセットアップ手順は [`RAILS_SETUP_GUIDE.md`](./RAILS_SETUP_GUIDE.md) をご覧ください。

## 🎨 デザインの特徴

### ポートフォリオページ
- ダーク系グラデーション（ブルー/スレート）
- プロフェッショナルな印象
- Mロゴ付きヘッダー

### ブログページ
- 明るいカラフルなグラデーション（バイオレット/パープル/フューシャ）
- カジュアルで親しみやすい雰囲気
- カテゴリごとの色分け

## 🔧 カスタマイズ

### 色の変更

`app/assets/stylesheets/application.tailwind.css`:

```css
:root {
  --color-primary: #1E40AF;
  --color-secondary: #334155;
  --color-accent: #FCD34D;
}
```

### 動的データの統合

```ruby
# コントローラー
def portfolio
  @projects = Project.all
end
```

```erb
<!-- ビュー -->
<% @projects.each do |project| %>
  <div><%= project.title %></div>
<% end %>
```

## 📞 サポート

質問や問題がある場合は、お気軽にお問い合わせください。

## 📄 ライセンス

このテンプレートは、あなたのプロジェクトで自由に使用・改変できます。

---

**Created with ❤️ using Figma Make**