# SEO/AEO実装ガイド

## 概要
このガイドは、ポートフォリオサイトにSEOとAI向けSEO（AEO）を実装するための詳細な手順を説明します。

## 1. SEO強化版レイアウトの使用

### 基本設定
`application_seo_enhanced.html.erb`を使用することで、以下のSEO機能が自動的に有効になります：

- 動的なタイトルタグ
- メタディスクリプション
- Open Graphタグ
- Twitterカード
- 構造化データ（JSON-LD）
- パフォーマンス最適化
- Core Web Vitals監視

### 実装方法
```ruby
# app/views/layouts/application.html.erb を置き換え
# または、特定のコントローラーで使用
class PagesController < ApplicationController
  layout 'application_seo_enhanced'
end
```

## 2. SEOヘルパーの使用

### ページごとのSEO設定例

#### ポートフォリオページ
```erb
<%# app/views/pages/portfolio.html.erb の冒頭に追加 %>
<% 
  page_title "宮川 剛 - ポートフォリオ"
  meta_description "30年のキャリアを持つシニアエンジニア宮川剛のポートフォリオ。Ruby on Rails、AI活用、要件定義から実装まで一貫した技術力を紹介。"
  meta_keywords ["宮川剛", "ポートフォリオ", "シニアエンジニア", "Ruby on Rails", "AI活用"]
  
  set_og_tags(
    title: "宮川 剛 - シニアエンジニアのポートフォリオ",
    description: "30年の経験を活かした技術発信",
    image: asset_url('portfolio-og.jpg'),
    type: 'website'
  )
%>
```

#### My Storyページ
```erb
<%# app/views/pages/my_story.html.erb の冒頭に追加 %>
<% 
  page_title "My Story - 30年のキャリア軌跡"
  meta_description "パソコンスクール講師からSE/PM、そしてAI活用エンジニアへ。宮川剛の30年にわたるIT業界でのキャリアストーリー。"
  meta_keywords ["My Story", "キャリア", "SE", "PM", "AI活用", "ChatGPT"]
  
  set_og_tags(
    title: "My Story - 宮川剛の30年のキャリア軌跡",
    description: "要件定義から実装まで一人でできる理由",
    image: asset_url('my-story-og.jpg')
  )
  
  # 構造化データを追加
  add_structured_data({
    "@context": "https://schema.org",
    "@type": "AboutPage",
    "name": "My Story",
    "description": "宮川剛の30年のキャリアストーリー",
    "url": my_story_url
  })
%>
```

#### ブログ記事ページ
```erb
<%# app/views/blog/article.html.erb の冒頭に追加 %>
<% 
  page_title @article.title
  meta_description @article.excerpt || truncate(@article.content, length: 155)
  meta_keywords @article.tags.pluck(:name)
  
  set_og_tags(
    title: @article.title,
    description: @article.excerpt,
    image: @article.featured_image_url,
    type: 'article'
  )
  
  # 記事の構造化データ
  add_structured_data(article_structured_data({
    title: @article.title,
    description: @article.excerpt,
    image: @article.featured_image_url,
    author: "宮川 剛",
    published_at: @article.published_at,
    updated_at: @article.updated_at,
    category: @article.category.name,
    keywords: @article.tags.pluck(:name),
    word_count: @article.word_count,
    url: article_url(@article)
  }))
  
  # パンくずリストの構造化データ
  add_structured_data(breadcrumb_structured_data([
    ["ホーム", root_path],
    ["ブログ", blog_path],
    [@article.category.name, blog_category_path(@article.category.slug)],
    [@article.title, nil]
  ]))
%>
```

## 3. 画像の最適化

### 遅延読み込み
```erb
<!-- 通常の画像 -->
<%= lazy_image_tag "portfolio/project-1.jpg", 
    alt: "プロジェクトのスクリーンショット",
    width: 800,
    height: 600,
    class: "rounded-lg shadow-md" %>

<!-- レスポンシブ画像 -->
<%= responsive_image_tag "blog/feature-image.jpg",
    alt: "記事のアイキャッチ画像",
    sizes: "(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 800px",
    class: "w-full h-auto" %>
```

## 4. FAQ構造化データの実装

```erb
<%# FAQセクションがあるページで使用 %>
<% 
  faqs = [
    {
      question: "ChatGPT APIの料金はどのくらいですか？",
      answer: "ChatGPT API（GPT-3.5-turbo）の料金は1,000トークンあたり$0.002です。日本語の場合、およそ700文字で1,000トークンになります。"
    },
    {
      question: "Railsとの連携は難しいですか？",
      answer: "OpenAIの公式Rubyクライアントを使用すれば、簡単に連携できます。基本的なAPIコールは数行のコードで実装可能です。"
    }
  ]
  
  add_structured_data(faq_structured_data(faqs))
%>

<section class="faq-section">
  <h2>よくある質問</h2>
  <% faqs.each do |faq| %>
    <div class="faq-item">
      <h3><%= faq[:question] %></h3>
      <p><%= faq[:answer] %></p>
    </div>
  <% end %>
</section>
```

## 5. チュートリアル記事のHowTo構造化データ

```erb
<% 
  how_to_data = {
    name: "ChatGPT APIとRailsで記事要約システムを作る方法",
    description: "OpenAI APIを使ってRailsアプリケーションに自動要約機能を実装する手順",
    image: asset_url('tutorials/chatgpt-rails.jpg'),
    total_time: "PT2H",  # 2時間
    cost: 500,  # 円
    supplies: ["OpenAI APIキー", "Rails 7.0以上の環境"],
    tools: ["Ruby", "Rails", "PostgreSQL"],
    steps: [
      {
        name: "OpenAI APIキーの取得",
        text: "OpenAIのウェブサイトでアカウントを作成し、APIキーを取得します。",
        url: article_url(@article, anchor: "step-1")
      },
      {
        name: "Gemのインストール",
        text: "Gemfileにopenai gemを追加してbundle installを実行します。",
        url: article_url(@article, anchor: "step-2")
      },
      # ... 他のステップ
    ]
  }
  
  add_structured_data(how_to_structured_data(how_to_data))
%>
```

## 6. パフォーマンス最適化のベストプラクティス

### リソースヒント
```erb
<%# ページ固有のリソースヒントを追加 %>
<% content_for :head do %>
  <!-- 重要な画像をプリロード -->
  <link rel="preload" as="image" href="<%= asset_path('hero-image.webp') %>" type="image/webp">
  
  <!-- 外部リソースへの事前接続 -->
  <link rel="preconnect" href="https://api.openai.com">
  
  <!-- 次に訪問される可能性が高いページをプリフェッチ -->
  <link rel="prefetch" href="<%= blog_path %>">
<% end %>
```

### JavaScript最適化
```erb
<%# ページ固有のJavaScriptを遅延読み込み %>
<% content_for :javascript do %>
  <%= javascript_include_tag 'blog_article_scroll', defer: true %>
  <%= javascript_include_tag 'syntax_highlighter', defer: true %>
<% end %>
```

## 7. 検索エンジン向け最適化チェックリスト

### 実装時の確認項目
- [ ] すべてのページに固有のタイトルタグがある
- [ ] メタディスクリプションが155文字以内で設定されている
- [ ] Open GraphとTwitterカードの画像が設定されている
- [ ] 構造化データが正しく実装されている（[Google構造化データテストツール](https://developers.google.com/search/docs/advanced/structured-data)で確認）
- [ ] 画像にalt属性が設定されている
- [ ] 画像サイズ（width/height）が明示されている
- [ ] 重要な画像にloading="eager"、その他にloading="lazy"が設定されている
- [ ] canonical URLが正しく設定されている
- [ ] robots.txtとsitemap.xmlが適切に設定されている

### AI向けSEO（AEO）チェックリスト
- [ ] コンテンツが質問-回答形式で構造化されている
- [ ] 技術用語にエンティティマークアップがある
- [ ] 関連トピックが適切にクラスタリングされている
- [ ] FAQセクションが実装されている
- [ ] ステップバイステップのガイドにHowTo構造化データが使用されている

## 8. 監視とメンテナンス

### Core Web Vitals監視
SEO強化版レイアウトには、Core Web Vitals（LCP、CLS、FID）の自動監視が含まれています。
本番環境では、これらの指標がコンソールに記録されます。

### 定期的な確認
- Google Search Consoleでのインデックス状況確認
- PageSpeed Insightsでのパフォーマンス測定
- 構造化データのエラーチェック
- メタデータの重複チェック

## まとめ
このガイドに従ってSEO/AEOを実装することで、検索エンジンとAIアシスタントの両方に最適化されたサイトを構築できます。
実装後は定期的にパフォーマンスを監視し、必要に応じて改善を行ってください。