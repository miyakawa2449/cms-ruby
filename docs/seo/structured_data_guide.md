# 構造化データ実装ガイド

## 概要

このガイドでは、Portfolio Siteで使用可能な構造化データ（Schema.org JSON-LD）の実装方法を説明します。構造化データを適切に実装することで、Google検索結果でのリッチリザルト表示が可能になり、クリック率の向上が期待できます。

## 対応スキーマ

| スキーマ | 用途 | 対応ヘルパー |
|---------|-----|-------------|
| FAQPage | よくある質問ページ | `faq_schema` |
| HowTo | チュートリアル・手順記事 | `how_to_schema` |
| BreadcrumbList | パンくずリスト | `breadcrumb_schema` |
| Organization | 組織・サイト情報 | `organization_schema` |
| Person | プロフィール・著者情報 | `person_schema` |
| WebSite | サイト全体（検索機能付き） | `website_schema` |

---

## 基本的な使用方法

### 1. ヘルパーのインクルード

`StructuredDataHelper`は`ApplicationHelper`に自動的にインクルードされているため、すべてのビューで使用可能です。

### 2. スキーマの生成とレンダリング

```erb
<%# ビューファイル内 %>
<% content_for :head do %>
  <%= structured_data_tag(faq_schema(@faqs)) %>
<% end %>
```

### 3. 複数スキーマの結合

```erb
<% content_for :head do %>
  <%= combined_structured_data_tag(
    breadcrumb_schema(@breadcrumbs),
    organization_schema
  ) %>
<% end %>
```

---

## 各スキーマの詳細

### FAQ Schema (FAQPage)

よくある質問ページに使用します。

#### 使用例

```erb
<%
  faqs = [
    { question: "ChatGPT APIの料金はどのくらいですか？",
      answer: "GPT-3.5-turboの場合、1,000トークンあたり$0.002です。" },
    { question: "Railsとの連携は難しいですか？",
      answer: "OpenAIの公式Rubyクライアントを使用すれば、数行のコードで実装可能です。" }
  ]
%>

<% content_for :head do %>
  <%= structured_data_tag(faq_schema(faqs)) %>
<% end %>

<section class="faq">
  <h2>よくある質問</h2>
  <% faqs.each do |faq| %>
    <div class="faq-item">
      <h3><%= faq[:question] %></h3>
      <p><%= faq[:answer] %></p>
    </div>
  <% end %>
</section>
```

#### 出力されるJSON-LD

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "ChatGPT APIの料金はどのくらいですか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "GPT-3.5-turboの場合、1,000トークンあたり$0.002です。"
      }
    }
  ]
}
```

---

### HowTo Schema

チュートリアルや手順を説明する記事に使用します。

#### 使用例

```erb
<%
  how_to_data = {
    name: "ChatGPT APIとRailsで記事要約システムを作る方法",
    description: "OpenAI APIを使ってRailsアプリケーションに自動要約機能を実装する手順",
    total_time: "PT2H",  # ISO 8601形式（2時間）
    cost: 500,           # 円（オプション）
    supplies: ["OpenAI APIキー", "Rails 7.0以上の環境"],  # オプション
    tools: ["Ruby", "Rails", "PostgreSQL"],  # オプション
    steps: [
      {
        name: "OpenAI APIキーの取得",
        text: "OpenAIのウェブサイトでアカウントを作成し、APIキーを取得します。",
        url: article_url(@article, anchor: "step-1")  # オプション
      },
      {
        name: "Gemのインストール",
        text: "Gemfileにopenai gemを追加してbundle installを実行します。"
      }
    ]
  }
%>

<% content_for :head do %>
  <%= structured_data_tag(how_to_schema(how_to_data)) %>
<% end %>
```

#### パラメータ

| パラメータ | 必須 | 説明 |
|-----------|------|-----|
| `:name` | 必須 | タイトル |
| `:description` | 推奨 | 説明文 |
| `:steps` | 必須 | 手順の配列 |
| `:total_time` | 推奨 | 所要時間（ISO 8601形式: PT1H30M = 1時間30分） |
| `:cost` | オプション | 費用 |
| `:currency` | オプション | 通貨コード（デフォルト: JPY） |
| `:supplies` | オプション | 必要な材料 |
| `:tools` | オプション | 必要なツール |
| `:image` | オプション | 画像URL |

---

### BreadcrumbList Schema

パンくずリストに使用します。

#### 使用例

```erb
<%
  breadcrumbs = [
    ["ホーム", root_url],
    ["ブログ", blog_url],
    [@category.name, category_url(@category)],
    [@article.title, nil]  # 現在のページはURLなし
  ]
%>

<% content_for :head do %>
  <%= structured_data_tag(breadcrumb_schema(breadcrumbs)) %>
<% end %>

<nav aria-label="パンくずリスト">
  <ol class="breadcrumb">
    <% breadcrumbs.each_with_index do |(name, url), index| %>
      <li>
        <% if url %>
          <%= link_to name, url %>
        <% else %>
          <span><%= name %></span>
        <% end %>
      </li>
    <% end %>
  </ol>
</nav>
```

---

### Organization Schema

サイト全体の組織情報に使用します。

#### 使用例

```erb
<%# app/views/layouts/application.html.erb %>
<% content_for :head do %>
  <%= structured_data_tag(organization_schema(
    name: "宮川 剛 - Portfolio",
    url: root_url,
    logo: asset_url("logo.png"),
    description: "シニアエンジニアの技術発信・ポートフォリオサイト",
    email: ENV['CONTACT_EMAIL'],
    social: {
      twitter: "https://twitter.com/miyakawa2449",
      github: "https://github.com/miyakawa2449"
    }
  )) %>
<% end %>
```

#### 環境変数によるデフォルト値

| 環境変数 | 説明 |
|---------|-----|
| `SITE_URL` | サイトURL |
| `SITE_NAME` | サイト名 |

---

### Person Schema

著者・プロフィールページに使用します。

#### 使用例

```erb
<% content_for :head do %>
  <%= structured_data_tag(person_schema(
    name: "宮川 剛",
    url: my_story_url,
    image: asset_url("profile.jpg"),
    job_title: "シニアエンジニア",
    description: "30年のキャリアを持つフルスタックエンジニア",
    social: {
      twitter: "https://twitter.com/miyakawa2449",
      github: "https://github.com/miyakawa2449"
    }
  )) %>
<% end %>
```

---

### WebSite Schema

サイト全体の情報と検索機能に使用します。

#### 使用例

```erb
<% content_for :head do %>
  <%= structured_data_tag(website_schema(
    name: "宮川 剛 - Portfolio",
    url: root_url,
    search_url: "#{root_url}blog/search?q={search_term_string}"
  )) %>
<% end %>
```

---

## 複数スキーマの結合

1ページに複数のスキーマを含める場合は、`combined_structured_data_tag`を使用します。

```erb
<% content_for :head do %>
  <%= combined_structured_data_tag(
    website_schema,
    organization_schema,
    breadcrumb_schema(@breadcrumbs)
  ) %>
<% end %>
```

---

## 検証方法

### Google Rich Results Test

実装後は、以下のツールで検証してください：

1. [Google Rich Results Test](https://search.google.com/test/rich-results)
   - URLまたはHTMLコードを入力
   - エラーや警告を確認

2. [Schema Markup Validator](https://validator.schema.org/)
   - より詳細な検証

### 開発環境での確認

```bash
# ページを表示してソースを確認
curl http://localhost:3000/blog/article-slug | grep "application/ld+json"
```

---

## ベストプラクティス

### 1. 正確なデータを使用

構造化データの内容は、実際のページコンテンツと一致させてください。

### 2. 必須プロパティを含める

各スキーマの必須プロパティは必ず含めてください。

### 3. 過度な使用を避ける

関連性のないスキーマを追加しても、SEO効果は期待できません。

### 4. 定期的な検証

Google Search Consoleで構造化データのエラーを監視してください。

---

## トラブルシューティング

### エラー: JSON-LDが表示されない

- `content_for :head`ブロック内に配置しているか確認
- レイアウトファイルで`yield :head`が呼ばれているか確認

### エラー: スキーマが無効

- 必須パラメータが渡されているか確認
- `nil`や空の配列が渡されていないか確認

### Google Search Consoleでエラー

- Rich Results Testで詳細を確認
- 必須プロパティの欠落を修正

---

## 参考リンク

- [Schema.org](https://schema.org/)
- [Google 構造化データガイドライン](https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data)
- [Google Rich Results Test](https://search.google.com/test/rich-results)

---

**作成日**: 2026-01-23
**作成者**: Claude Code
**バージョン**: 1.0
