# Phase 4.3 検索機能 UX改善 - Claude Code実装ガイド

## 🎯 実装の目的

サイドバーのカテゴリナビゲーションと検索フィルターの混同を解消し、ユーザーが直感的に操作できるUIを実現する。

## 📋 実装手順

### Step 1: Modelの実装

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  # 既存のコード...
  
  # 検索スコープ
  scope :search, ->(query) {
    return all if query.blank?
    
    sanitized_query = sanitize_sql_like(query.to_s.strip)
    where(
      "title ILIKE :q OR excerpt ILIKE :q OR content ILIKE :q",
      q: "%#{sanitized_query}%"
    )
  }
  
  # カテゴリフィルター（単数）
  scope :by_category, ->(category_id) {
    return all if category_id.blank?
    joins(:article_categories).where(article_categories: { category_id: category_id })
  }
  
  # タグフィルター（単数）
  scope :by_tag, ->(tag_id) {
    return all if tag_id.blank?
    joins(:article_tags).where(article_tags: { tag_id: tag_id })
  }
end
```

### Step 2: Controllerの実装

```ruby
# app/controllers/blog_controller.rb
class BlogController < ApplicationController
  def index
    @articles = Article.published
                      .search(params[:q])
                      .by_category(params[:category_id])
                      .by_tag(params[:tag_id])
                      .includes(:categories, :tags, thumbnail_image_attachment: :blob)
                      .order(published_at: :desc)
                      .page(params[:page])
                      .per(10)
    
    @query = params[:q]
    @selected_category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
    @selected_tag = Tag.find_by(id: params[:tag_id]) if params[:tag_id].present?
    
    @categories = Category.with_published_articles.order(:name)
    @tags = Tag.with_published_articles.order(:name)
    
    if search_active?
      set_meta_tags noindex: true
    end
  end
  
  private
  
  def search_active?
    params[:q].present? || params[:category_id].present? || params[:tag_id].present?
  end
end
```

### Step 3: 検索エリアのビュー

```erb
<!-- app/views/blog/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <!-- 検索エリア -->
  <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
    <h2 class="text-lg font-semibold mb-4 flex items-center">
      <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
      </svg>
      記事を検索
    </h2>
    
    <%= form_with url: blog_index_path, method: :get, local: true do |f| %>
      <div class="mb-4">
        <div class="flex gap-2">
          <%= f.text_field :q, 
              value: params[:q], 
              placeholder: "キーワードを入力...", 
              class: "flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500" %>
          <%= f.submit "検索", class: "px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700" %>
        </div>
      </div>
      
      <div class="flex flex-wrap gap-4 items-center text-sm">
        <span class="text-gray-600 font-medium">絞り込み:</span>
        
        <%= f.select :category_id, 
            options_for_select([['すべてのカテゴリ', '']] + @categories.map { |c| [c.name, c.id] }, params[:category_id]),
            {},
            class: "px-3 py-2 border rounded-lg",
            onchange: "this.form.requestSubmit()" %>
        
        <%= f.select :tag_id,
            options_for_select([['すべてのタグ', '']] + @tags.map { |t| [t.name, t.id] }, params[:tag_id]),
            {},
            class: "px-3 py-2 border rounded-lg",
            onchange: "this.form.requestSubmit()" %>
      </div>
    <% end %>
    
    <% if params[:q].present? || params[:category_id].present? || params[:tag_id].present? %>
      <div class="mt-4 pt-4 border-t">
        <div class="flex items-center justify-between flex-wrap gap-2">
          <div class="text-gray-700">
            <% if params[:q].present? %>
              「<span class="font-semibold text-blue-600"><%= params[:q] %></span>」の検索結果: 
            <% else %>
              検索結果: 
            <% end %>
            <span class="font-semibold"><%= @articles.total_count %></span>件
            
            <div class="inline-flex gap-2 ml-2">
              <% if @selected_category %>
                <%= link_to blog_index_path(q: params[:q], tag_id: params[:tag_id]), 
                    class: "inline-flex items-center px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs hover:bg-blue-200" do %>
                  カテゴリ: <%= @selected_category.name %>
                  <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                  </svg>
                <% end %>
              <% end %>
              
              <% if @selected_tag %>
                <%= link_to blog_index_path(q: params[:q], category_id: params[:category_id]), 
                    class: "inline-flex items-center px-2 py-1 bg-green-100 text-green-800 rounded text-xs hover:bg-green-200" do %>
                  タグ: <%= @selected_tag.name %>
                  <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                  </svg>
                <% end %>
              <% end %>
            </div>
          </div>
          
          <%= link_to blog_index_path, class: "text-blue-600 hover:underline text-sm font-medium" do %>
            ✕ すべてクリア
          <% end %>
        </div>
      </div>
    <% end %>
  </div>

  <!-- 記事一覧 -->
  <div class="grid gap-6">
    <% if @articles.any? %>
      <% @articles.each do |article| %>
        <%= render 'article_card', article: article %>
      <% end %>
    <% else %>
      <div class="text-center py-16 bg-white rounded-lg shadow-sm">
        <svg class="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <p class="text-lg font-medium text-gray-700 mb-2">記事が見つかりませんでした</p>
        <p class="text-sm text-gray-500 mb-4">検索条件を変更してお試しください</p>
        <%= link_to "すべての記事を見る", blog_index_path, 
            class: "inline-block px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700" %>
      </div>
    <% end %>
  </div>
  
  <%= paginate @articles %>
</div>
```

### Step 4: サイドバーのビュー

```erb
<!-- app/views/blog/_sidebar.html.erb -->
<div class="bg-white rounded-lg shadow-sm p-6">
  <h3 class="font-bold text-lg mb-4">カテゴリ</h3>
  
  <div class="space-y-1">
    <% @categories.each do |category| %>
      <%= link_to blog_index_path(category_id: category.id), 
          class: "block px-4 py-2 rounded-lg transition #{params[:category_id] == category.id.to_s && params[:q].blank? && params[:tag_id].blank? ? 'bg-blue-50 border-l-4 border-blue-500 text-blue-700 font-medium' : 'hover:bg-gray-50 text-gray-700'}" do %>
        <div class="flex items-center justify-between">
          <span><%= category.name %></span>
          <span class="text-sm text-gray-500">(<%= category.articles_count %>)</span>
        </div>
      <% end %>
    <% end %>
  </div>
  
  <% if params[:category_id].present? && params[:q].blank? && params[:tag_id].blank? %>
    <div class="mt-4 pt-4 border-t">
      <%= link_to blog_index_path, 
          class: "block text-center px-4 py-2 text-blue-600 hover:bg-blue-50 rounded-lg text-sm font-medium" do %>
        ✕ カテゴリをクリア
      <% end %>
    </div>
  <% end %>
  
  <% if params[:q].present? || params[:tag_id].present? %>
    <div class="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg text-xs text-blue-800">
      <p class="font-medium mb-1">ℹ️ 検索中</p>
      <p>カテゴリをクリックすると検索条件がクリアされます</p>
    </div>
  <% end %>
</div>
```

### Step 5: ヘルパーの実装

```ruby
# app/helpers/search_helper.rb
module SearchHelper
  def highlight_keywords(text, query)
    return text if query.blank? || text.blank?
    
    escaped_text = ERB::Util.html_escape(text)
    keywords = query.split(/\s+/).reject(&:blank?)
    
    keywords.each do |keyword|
      escaped_keyword = Regexp.escape(keyword)
      escaped_text = escaped_text.gsub(
        /#{escaped_keyword}/i,
        '<mark class="bg-yellow-200 px-1 rounded">\0</mark>'
      )
    end
    
    escaped_text.html_safe
  end
end
```

## ✅ 実装完了チェックリスト

- [ ] キーワード検索が動作する
- [ ] カテゴリフィルターが検索エリア内で動作する
- [ ] タグフィルターが検索エリア内で動作する
- [ ] サイドバーのカテゴリクリックで検索条件がクリアされる
- [ ] 適用中のフィルターがバッジで表示される
- [ ] 各フィルターを個別に削除できる
- [ ] 「すべてクリア」ボタンが動作する
- [ ] 0件時に分かりやすいメッセージが表示される
- [ ] SQLインジェクション対策が機能している
- [ ] XSS対策が機能している
- [ ] N+1クエリが発生していない

## 🧪 必須テストケース

```ruby
# spec/models/article_spec.rb
it 'SQLワイルドカード（%）を含むキーワードで検索できる' do
  article = create(:article, title: '100%達成')
  result = Article.search('100%')
  expect(result).to include(article)
end

# spec/controllers/blog_controller_spec.rb
it 'サイドバーのカテゴリクリックで検索条件がクリアされる' do
  category = create(:category)
  get :index, params: { category_id: category.id }
  expect(assigns(:query)).to be_nil
end

# spec/helpers/search_helper_spec.rb
it 'キーワードハイライトでXSS攻撃を防ぐ' do
  text = '<script>alert("XSS")</script>'
  result = helper.highlight_keywords(text, 'script')
  expect(result).not_to include('<script>')
end
```
