# Rails用テンプレート - セットアップガイド

このディレクトリには、Figma Makeで作成したReactデザインをRuby on Railsで使用するためのERBテンプレートが含まれています。

## 📁 ファイル構成

```
rails_templates/
├── app/
│   ├── assets/
│   │   └── stylesheets/
│   │       └── application.tailwind.css  # Tailwind CSSスタイル
│   ├── controllers/
│   │   ├── pages_controller.rb           # ページコントローラー
│   │   └── blog_controller.rb            # ブログコントローラー
│   └── views/
│       ├── layouts/
│       │   └── application.html.erb      # メインレイアウト
│       ├── shared/
│       │   ├── _header.html.erb          # ヘッダーパーシャル
│       │   └── _footer.html.erb          # フッターパーシャル
│       ├── pages/
│       │   └── portfolio.html.erb        # ポートフォリオページ
│       └── blog/
└── config/
    └── routes.rb                         # ルーティング設定
```

## 🚀 Rails プロジェクトへの統合手順

### 1. Tailwind CSS のインストール

```bash
# Railsプロジェクトディレクトリで実行
bundle add tailwindcss-rails
rails tailwindcss:install
```

### 2. ファイルのコピー

以下のファイルを、あなたのRailsプロジェクトの対応するディレクトリにコピーしてください：

```bash
# コントローラー
cp rails_templates/app/controllers/* your-rails-app/app/controllers/

# ビュー
cp -r rails_templates/app/views/* your-rails-app/app/views/

# スタイルシート（既存のファイルに追記または上書き）
cp rails_templates/app/assets/stylesheets/application.tailwind.css your-rails-app/app/assets/stylesheets/

# ルーティング（既存のroutes.rbにマージ）
# routes.rbの内容を手動でコピーしてください
```

### 3. Tailwind CSS 設定の確認

`config/tailwind.config.js` が存在することを確認：

```javascript
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ]
}
```

### 4. アセットのプリコンパイル

開発環境で動作確認：

```bash
rails assets:precompile
rails server
```

ブラウザで `http://localhost:3000` にアクセス

## 📝 使用方法

### ヘッダーの使用

```erb
<!-- ポートフォリオページ用 -->
<%= render 'shared/header', variant: 'portfolio', show_search: true %>

<!-- ブログページ用 -->
<%= render 'shared/header', variant: 'blog', show_search: true %>

<!-- My Storyページ用 -->
<%= render 'shared/header', variant: 'story', show_search: false %>
```

### フッターの使用

```erb
<!-- デフォルト -->
<%= render 'shared/footer', variant: 'portfolio' %>

<!-- My Story用 -->
<%= render 'shared/footer', variant: 'story' %>
```

### ルーティングヘルパー

```erb
<!-- リンクの作成 -->
<%= link_to 'ポートフォリオ', root_path %>
<%= link_to 'My Story', my_story_path %>
<%= link_to 'ブログ', blog_path %>
<%= link_to 'カテゴリ', blog_category_path(slug: 'ai-ml') %>
<%= link_to '記事', blog_article_path(slug: 'article-slug') %>
```

## 🎨 カスタマイズ

### 色の変更

`app/assets/stylesheets/application.tailwind.css` の `:root` セクションを編集：

```css
:root {
  --color-primary: #1E40AF;      /* メインカラー */
  --color-secondary: #334155;    /* セカンダリカラー */
  --color-accent: #FCD34D;       /* アクセントカラー */
}
```

### 動的データの統合

#### コントローラーでデータを取得

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def portfolio
    @projects = Project.all
    @blog_posts = BlogPost.published.limit(2)
  end
end
```

#### ビューで表示

```erb
<!-- app/views/pages/portfolio.html.erb -->
<% @projects.each do |project| %>
  <div class="border border-gray-200 rounded-lg overflow-hidden">
    <%= image_tag project.image_url, class: "h-48 w-full object-cover" %>
    <div class="p-6">
      <h3 class="text-lg font-bold mb-2"><%= project.title %></h3>
      <p class="text-gray-600 mb-4"><%= project.description %></p>
      <div class="flex flex-wrap gap-2">
        <% project.tags.each do |tag| %>
          <span class="bg-blue-100 text-blue-800 px-2 py-1 rounded text-sm">
            <%= tag.name %>
          </span>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

## 🔧 追加ページの作成

### My Storyページ、ブログページの作成

まだ作成していないページ（My Story、Blog Index、Blog Category、Blog Article）も同様の手順で作成できます。

必要に応じて追加のERBファイルを作成します：

```bash
# My Storyページ
touch app/views/pages/my_story.html.erb

# ブログページ
touch app/views/blog/index.html.erb
touch app/views/blog/category.html.erb
touch app/views/blog/article.html.erb
```

## 🗄️ データベースモデルの例

ブログ機能を実装する場合のモデル例：

```bash
# マイグレーションの作成
rails generate model Article title:string slug:string content:text category:string published:boolean published_at:datetime
rails generate model Project title:string description:text image_url:string
rails generate model Tag name:string

rails db:migrate
```

## 📱 レスポンシブデザイン

すべてのページはTailwind CSSのレスポンシブユーティリティを使用しており、モバイルファーストで設計されています：

- `sm:` - 640px以上
- `md:` - 768px以上
- `lg:` - 1024px以上
- `xl:` - 1280px以上

## 🚢 本番環境へのデプロイ

### アセットのプリコンパイル

```bash
RAILS_ENV=production rails assets:precompile
```

### 環境変数の設定

必要に応じて、以下の環境変数を設定：

```bash
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

## 📚 参考リンク

- [Ruby on Rails](https://rubyonrails.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [tailwindcss-rails gem](https://github.com/rails/tailwindcss-rails)

## 🐛 トラブルシューティング

### スタイルが適用されない

```bash
# Tailwindのビルドを再実行
rails tailwindcss:build

# または開発モードでウォッチ
rails tailwindcss:watch
```

### ルーティングエラー

```bash
# ルートの確認
rails routes | grep pages
rails routes | grep blog
```

### アセットが読み込まれない

`config/environments/development.rb` を確認：

```ruby
config.assets.debug = true
config.assets.compile = true
```

## 💡 ヒント

1. **画像の配置**: 画像は `app/assets/images/` または `public/images/` に配置
2. **JavaScriptの追加**: Stimulusコントローラーで動的機能を追加可能
3. **SEO対策**: `<title>` タグと `<meta>` タグをビューごとにカスタマイズ

```erb
<% content_for :title, "ページタイトル - Miyakawa Codes" %>
<% content_for :description, "ページの説明文" %>
```

---

ご質問やサポートが必要な場合は、お気軽にお問い合わせください！
