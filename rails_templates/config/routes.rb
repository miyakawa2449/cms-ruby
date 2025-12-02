Rails.application.routes.draw do
  # ポートフォリオページ（トップページ）
  root 'pages#portfolio'
  
  # My Story ページ
  get 'my-story', to: 'pages#my_story', as: 'my_story'
  
  # ブログ関連
  get 'blog', to: 'blog#index', as: 'blog'
  get 'blog/category/:slug', to: 'blog#category', as: 'blog_category'
  get 'blog/article/:slug', to: 'blog#article', as: 'blog_article'
  
  # ヘルスチェック（デフォルト）
  get "up" => "rails/health#show", as: :rails_health_check
end
