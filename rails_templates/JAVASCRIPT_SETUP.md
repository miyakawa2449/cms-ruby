# JavaScript セットアップガイド

このドキュメントでは、スクロールアニメーションなどのJavaScript機能をRailsプロジェクトに統合する方法を説明します。

## 📁 含まれるJavaScriptファイル

### 1. `app/javascript/my_story_animations.js`
- **用途**: My Storyページのスクロールアニメーション
- **機能**: `.scroll-reveal` クラスを持つ要素がビューポートに入ったときにフェードイン

### 2. `app/javascript/blog_article_scroll.js`
- **用途**: ブログ記事詳細ページのスクロール進捗バー
- **機能**: ページ上部に読書進捗を表示

## 🚀 セットアップ手順

### オプション1: Import Maps を使用（Rails 7+推奨）

#### 1. JavaScriptファイルをコピー

```bash
cp rails_templates/app/javascript/* your-rails-project/app/javascript/
```

#### 2. `config/importmap.rb` に追加

```ruby
# config/importmap.rb
pin "application", preload: true
pin "my_story_animations", preload: true
pin "blog_article_scroll", preload: true
```

#### 3. ビューファイルで使用

各ページテンプレートで、既に `content_for :javascript` ブロックが含まれています：

```erb
<% content_for :javascript do %>
  <%= javascript_include_tag 'my_story_animations', defer: true %>
<% end %>
```

### オプション2: Sprockets を使用（Rails 6以前）

#### 1. JavaScriptファイルをコピー

```bash
cp rails_templates/app/javascript/* your-rails-project/app/assets/javascripts/
```

#### 2. `application.js` に追加

```javascript
// app/assets/javascripts/application.js
//= require my_story_animations
//= require blog_article_scroll
```

#### 3. 条件付き読み込み

特定のページでのみ読み込む場合：

```erb
<% content_for :javascript do %>
  <%= javascript_include_tag 'my_story_animations' %>
<% end %>
```

### オプション3: esbuild/Webpack を使用

#### 1. JavaScriptファイルをコピー

```bash
cp rails_templates/app/javascript/* your-rails-project/app/javascript/
```

#### 2. エントリーポイントで読み込み

```javascript
// app/javascript/application.js
import "./my_story_animations";
import "./blog_article_scroll";
```

## 📝 使用方法

### My Story ページ

**HTML要素に `.scroll-reveal` クラスを追加するだけ：**

```erb
<div class="scroll-reveal">
  <!-- スクロール時にフェードインするコンテンツ -->
</div>
```

**CSSは既に `application.tailwind.css` に含まれています：**

```css
.scroll-reveal {
  opacity: 0;
  transform: translateY(30px);
  transition: all 0.6s ease;
}

.scroll-reveal.revealed {
  opacity: 1;
  transform: translateY(0);
}
```

### ブログ記事ページ

**プログレスバー用の要素を追加：**

```erb
<div class="progress-bar" id="progressBar" style="width: 0%;"></div>
```

**CSSも追加：**

```css
.progress-bar {
  position: fixed;
  top: 0;
  left: 0;
  height: 3px;
  background: linear-gradient(90deg, #3b82f6, #8b5cf6);
  z-index: 9999;
  transition: width 0.2s ease;
}
```

## 🎨 CSSの追加

`app/assets/stylesheets/application.tailwind.css` に以下を追加してください：

```css
/* Scroll Reveal Animation */
.scroll-reveal {
  opacity: 0;
  transform: translateY(30px);
  transition: all 0.6s ease;
}

.scroll-reveal.revealed {
  opacity: 1;
  transform: translateY(0);
}

/* Progress Bar */
.progress-bar {
  position: fixed;
  top: 0;
  left: 0;
  height: 3px;
  background: linear-gradient(90deg, #3b82f6, #8b5cf6);
  z-index: 9999;
  transition: width 0.2s ease;
}

/* Floating Share Buttons */
.floating-share {
  position: fixed;
  left: 2rem;
  top: 50%;
  transform: translateY(-50%);
  z-index: 40;
}

/* Table of Contents */
.toc {
  background: linear-gradient(135deg, #f0f9ff 0%, #e0e7ff 100%);
  border-left: 4px solid #3b82f6;
}
```

## 🔧 カスタマイズ

### アニメーション速度を変更

```css
.scroll-reveal {
  transition: all 0.8s ease; /* 0.6s → 0.8s に変更 */
}
```

### トリガー位置を調整

```javascript
// my_story_animations.js
const elementVisible = 100; // 150 → 100 に変更（早めに表示）
```

### プログレスバーの色を変更

```css
.progress-bar {
  background: linear-gradient(90deg, #ef4444, #f97316); /* 赤〜オレンジ */
}
```

## 🐛 トラブルシューティング

### JavaScriptが動作しない場合

1. **ブラウザのコンソールを確認**
   - F12キーを押してデベロッパーツールを開く
   - エラーメッセージがないか確認

2. **ファイルが読み込まれているか確認**
   ```erb
   <%= javascript_include_tag 'my_story_animations', defer: true %>
   ```

3. **Turboを使用している場合**
   ```javascript
   // DOMContentLoaded → turbo:load に変更
   document.addEventListener('turbo:load', function() {
     // コード
   });
   ```

### アニメーションが一度しか動作しない

Turbo Driveを使用している場合、ページ遷移時にイベントリスナーが削除されます。
`turbo:load` イベントを使用してください。

## 📚 参考情報

- [Rails Import Maps](https://github.com/rails/importmap-rails)
- [Turbo Drive](https://turbo.hotwired.dev/handbook/drive)
- [Intersection Observer API](https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API)（より高度な実装）

---

**質問がある場合は、お気軽にお問い合わせください！**
