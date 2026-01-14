# ビュー＆フロントエンド仕様書

## フロントエンド技術スタック

### 主要技術
- **CSS Framework**: Tailwind CSS 3.x
- **JavaScript**: Stimulus (Hotwire)
- **Turbo**: Rails 8.1標準（Turbo Drive, Turbo Frames）
- **アセット管理**: Propshaft（Rails 8.1新機能）
- **アイコン**: Heroicons
- **フォント**: Google Fonts (Inter)

### ビルドツール
- **PostCSS**: Tailwind CSS処理
- **ESBuild**: JavaScript処理
- **Importmap**: ES modules管理

## ビュー構造

### レイアウトファイル

#### application.html.erb（メインレイアウト）
```erb
<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title><%= content_for(:title) || "Miyakawa Portfolio" %></title>
    
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    
    <!-- SEO/OGP Meta Tags -->
    <%= render 'shared/meta_tags' %>
    
    <!-- Stylesheets -->
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    
    <!-- JavaScript -->
    <%= javascript_importmap_tags %>
    
    <!-- PWA -->
    <link rel="manifest" href="/manifest.json">
    
    <!-- Favicon -->
    <%= favicon_link_tag 'favicon.ico' %>
  </head>

  <body class="min-h-screen bg-gray-50">
    <%= render 'shared/header' unless @hide_header %>
    
    <main class="flex-grow">
      <%= yield %>
    </main>
    
    <%= render 'shared/footer' unless @hide_footer %>
    <%= render 'shared/flash_messages' %>
  </body>
</html>
```

#### admin.html.erb（管理画面レイアウト）
```erb
<!DOCTYPE html>
<html lang="ja">
  <head>
    <!-- 省略: メタタグ等 -->
    <%= stylesheet_link_tag "admin", "data-turbo-track": "reload" %>
  </head>

  <body class="bg-gray-100">
    <div class="flex h-screen">
      <!-- サイドバー -->
      <%= render 'admin/shared/sidebar' %>
      
      <!-- メインコンテンツ -->
      <div class="flex-1 flex flex-col overflow-hidden">
        <!-- ヘッダー -->
        <%= render 'admin/shared/header' %>
        
        <!-- コンテンツエリア -->
        <main class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-100">
          <div class="container mx-auto px-6 py-8">
            <%= render 'admin/shared/breadcrumbs' %>
            <%= yield %>
          </div>
        </main>
      </div>
    </div>
  </body>
</html>
```

### 共通パーツ（Partials）

#### shared/_header.html.erb
```erb
<header class="bg-white shadow-sm sticky top-0 z-50" data-controller="navigation">
  <nav class="container mx-auto px-6 py-4">
    <div class="flex items-center justify-between">
      <!-- ロゴ -->
      <%= link_to root_path, class: "text-2xl font-bold text-gray-800" do %>
        Miyakawa<span class="text-blue-600">.</span>
      <% end %>
      
      <!-- デスクトップナビゲーション -->
      <div class="hidden md:flex items-center space-x-8">
        <%= link_to "Home", root_path, class: nav_link_class(root_path) %>
        <%= link_to "Blog", blog_path, class: nav_link_class(blog_path) %>
        <%= link_to "My Story", my_story_path, class: nav_link_class(my_story_path) %>
        <a href="#contact" class="<%= nav_link_class('#contact') %>">Contact</a>
      </div>
      
      <!-- モバイルメニューボタン -->
      <button data-action="navigation#toggle" class="md:hidden">
        <!-- ハンバーガーアイコン -->
      </button>
    </div>
    
    <!-- モバイルメニュー -->
    <div data-navigation-target="menu" class="hidden md:hidden mt-4">
      <!-- モバイルナビゲーション -->
    </div>
  </nav>
</header>
```

### ポートフォリオビュー

#### portfolio/index.html.erb
```erb
<% content_for :title, "Miyakawa Portfolio - シニアエンジニアの技術発信" %>

<div data-controller="smooth-scroll">
  <!-- 各セクションの動的読み込み -->
  <% @sections.each do |section| %>
    <% if section.active_content %>
      <%= render "portfolio/sections/#{section.name}", 
          section: section, 
          content: section.active_content %>
    <% end %>
  <% end %>
  
  <!-- スクロールトップボタン -->
  <%= render 'shared/scroll_to_top' %>
</div>
```

#### portfolio/sections/_hero.html.erb
```erb
<section id="hero" class="min-h-screen flex items-center justify-center relative overflow-hidden">
  <!-- 背景画像/動画 -->
  <% if content.hero_image.attached? %>
    <div class="absolute inset-0 z-0">
      <%= image_tag content.hero_image, 
          class: "w-full h-full object-cover", 
          alt: "Hero background" %>
      <div class="absolute inset-0 bg-black bg-opacity-50"></div>
    </div>
  <% end %>
  
  <!-- コンテンツ -->
  <div class="relative z-10 text-center text-white px-6">
    <h1 class="text-5xl md:text-7xl font-bold mb-6 animate-fade-in">
      <%= content.main_title || "宮川剛" %>
    </h1>
    
    <p class="text-xl md:text-2xl mb-8 animate-fade-in-delay">
      <%= content.sub_title || "シニアエンジニア / AIエンジニア" %>
    </p>
    
    <% if content.cta_button_text.present? %>
      <a href="#contact" 
         class="bg-blue-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:bg-blue-700 transition-colors inline-block animate-fade-in-delay-2">
        <%= content.cta_button_text %>
      </a>
    <% end %>
  </div>
  
  <!-- スクロールインジケーター -->
  <div class="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
    <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor">
      <!-- 下矢印SVG -->
    </svg>
  </div>
</section>
```

### ブログビュー

#### blog/index.html.erb
```erb
<div class="container mx-auto px-6 py-12">
  <!-- ヘッダー -->
  <div class="text-center mb-12">
    <h1 class="text-4xl font-bold text-gray-900 mb-4">技術ブログ</h1>
    <p class="text-xl text-gray-600">最新の技術情報と開発ノウハウを発信</p>
  </div>
  
  <!-- 検索・フィルター -->
  <div class="mb-8" data-controller="blog-filter">
    <%= render 'blog/search_form' %>
    <%= render 'blog/category_filter', categories: @categories %>
  </div>
  
  <!-- 記事一覧 -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
    <% @articles.each do |article| %>
      <%= render 'blog/article_card', article: article %>
    <% end %>
  </div>
  
  <!-- ページネーション -->
  <%= render 'shared/pagination', items: @articles %>
</div>
```

#### blog/_article_card.html.erb
```erb
<article class="bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow">
  <%= link_to blog_article_path(article), class: "block" do %>
    <!-- サムネイル -->
    <div class="aspect-w-16 aspect-h-9 bg-gray-200 rounded-t-lg overflow-hidden">
      <% if article.thumbnail_image.attached? %>
        <%= image_tag article.thumbnail_image.variant(resize_to_fill: [400, 225]), 
            class: "w-full h-full object-cover",
            alt: article.title,
            loading: "lazy" %>
      <% else %>
        <div class="flex items-center justify-center h-full">
          <svg class="w-16 h-16 text-gray-400"><!-- 画像なしアイコン --></svg>
        </div>
      <% end %>
    </div>
    
    <!-- コンテンツ -->
    <div class="p-6">
      <!-- カテゴリ -->
      <div class="flex gap-2 mb-3">
        <% article.categories.limit(2).each do |category| %>
          <span class="text-xs font-medium text-<%= category.color || 'blue' %>-600 
                       bg-<%= category.color || 'blue' %>-100 px-2 py-1 rounded">
            <%= category.name %>
          </span>
        <% end %>
      </div>
      
      <!-- タイトル -->
      <h2 class="text-xl font-bold text-gray-900 mb-2 line-clamp-2">
        <%= article.title %>
      </h2>
      
      <!-- 抜粋 -->
      <p class="text-gray-600 line-clamp-3 mb-4">
        <%= strip_tags(article.excerpt || article.content).truncate(150) %>
      </p>
      
      <!-- メタ情報 -->
      <div class="flex items-center justify-between text-sm text-gray-500">
        <time datetime="<%= article.published_at&.iso8601 %>">
          <%= article.published_at&.strftime("%Y年%m月%d日") %>
        </time>
        <span><%= article.content_reading_time %> 分で読了</span>
      </div>
    </div>
  <% end %>
</article>
```

### 管理画面ビュー

#### admin/articles/index.html.erb
```erb
<div class="bg-white shadow rounded-lg">
  <!-- ヘッダー -->
  <div class="px-6 py-4 border-b border-gray-200">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-semibold text-gray-800">記事管理</h1>
      <%= link_to new_admin_article_path, 
          class: "bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700" do %>
        <svg class="w-5 h-5 inline mr-2"><!-- プラスアイコン --></svg>
        新規作成
      <% end %>
    </div>
  </div>
  
  <!-- フィルター -->
  <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
    <%= form_with url: admin_articles_path, method: :get, 
        data: { controller: "auto-submit" } do |f| %>
      <div class="flex gap-4">
        <%= f.select :status, 
            options_for_select(article_status_options, params[:status]),
            { include_blank: "全てのステータス" },
            class: "form-select" %>
        <%= f.text_field :q, 
            placeholder: "検索...",
            value: params[:q],
            class: "form-input" %>
      </div>
    <% end %>
  </div>
  
  <!-- テーブル -->
  <div class="overflow-x-auto">
    <table class="min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            タイトル
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            ステータス
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            カテゴリ
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            公開日
          </th>
          <th class="relative px-6 py-3"><span class="sr-only">操作</span></th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        <% @articles.each do |article| %>
          <tr class="hover:bg-gray-50">
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="flex items-center">
                <div>
                  <div class="text-sm font-medium text-gray-900">
                    <%= link_to article.title, 
                        edit_admin_article_path(article),
                        class: "hover:text-blue-600" %>
                  </div>
                  <div class="text-sm text-gray-500">
                    <%= article.slug %>
                  </div>
                </div>
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <%= render 'admin/shared/status_badge', status: article.status %>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              <%= article.category_names %>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
              <%= article.published_at&.strftime("%Y/%m/%d") || "-" %>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <%= render 'admin/shared/actions_dropdown', resource: article %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
  
  <!-- ページネーション -->
  <div class="px-6 py-4 border-t border-gray-200">
    <%= paginate @articles %>
  </div>
</div>
```

## Stimulus Controllers

### NavigationController
```javascript
// app/javascript/controllers/navigation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    this.closeMenu = this.closeMenu.bind(this)
  }
  
  toggle() {
    this.menuTarget.classList.toggle("hidden")
    
    if (!this.menuTarget.classList.contains("hidden")) {
      document.addEventListener("click", this.closeMenu)
    }
  }
  
  closeMenu(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      document.removeEventListener("click", this.closeMenu)
    }
  }
}
```

### SmoothScrollController
```javascript
// app/javascript/controllers/smooth_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", this.handleClick.bind(this))
  }
  
  handleClick(event) {
    const link = event.target.closest('a[href^="#"]')
    if (!link) return
    
    event.preventDefault()
    const targetId = link.getAttribute("href")
    const target = document.querySelector(targetId)
    
    if (target) {
      target.scrollIntoView({
        behavior: "smooth",
        block: "start"
      })
    }
  }
}
```

### FormSubmitController
```javascript
// app/javascript/controllers/form_submit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "spinner"]
  
  connect() {
    this.element.addEventListener("turbo:submit-start", () => {
      this.showLoading()
    })
    
    this.element.addEventListener("turbo:submit-end", () => {
      this.hideLoading()
    })
  }
  
  showLoading() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("opacity-50")
    }
    
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
  }
  
  hideLoading() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("opacity-50")
    }
    
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
  }
}
```

## Tailwind CSS カスタマイズ

### tailwind.config.js
```javascript
module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          // ... 他の色定義
          900: '#1e3a8a',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'fade-in-delay': 'fadeIn 0.5s ease-in-out 0.2s both',
        'fade-in-delay-2': 'fadeIn 0.5s ease-in-out 0.4s both',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
  ],
}
```

## パフォーマンス最適化

### 画像の遅延読み込み
```erb
<%= image_tag article.thumbnail_image,
    loading: "lazy",
    class: "w-full h-full object-cover" %>
```

### Turbo Frame使用
```erb
<%= turbo_frame_tag "article_list" do %>
  <!-- 動的に更新される部分 -->
<% end %>
```

### キャッシュ活用
```erb
<% cache [article, article.updated_at] do %>
  <%= render 'article_card', article: article %>
<% end %>
```

## レスポンシブデザイン

### ブレークポイント
- `sm`: 640px以上
- `md`: 768px以上  
- `lg`: 1024px以上
- `xl`: 1280px以上
- `2xl`: 1536px以上

### モバイルファースト設計
```erb
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- モバイル: 1カラム、タブレット: 2カラム、デスクトップ: 3カラム -->
</div>
```