Rails.application.routes.draw do
  # SEO関連
  get "/sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }
  get "/feed.rss", to: "feeds#rss", defaults: { format: "rss" }, as: :feed_rss
  get "/feed.atom", to: "feeds#atom", defaults: { format: "atom" }, as: :feed_atom

  # Simple test
  get "test" => "simple_test#index"
  
  # Contact form submission
  post "contacts", to: "contacts#create"
  # NOTE: registrations skipped for security (single-user CMS)
  # Future: Remove skip when implementing multi-tenant CMS sales version
  devise_for :admin_users, path: 'admin-secure-panel-miyakawa2449',
    skip: [:registrations],
    controllers: { sessions: 'admin_users/sessions' }
  
  # Admin routes (セキュリティのため長いURL使用)
  namespace :admin, path: 'admin-secure-panel-miyakawa2449' do
    resource :site_settings, only: [:show, :update]
    resources :contacts, only: [:index, :show, :edit, :update, :destroy]
    root to: "dashboard#index", as: :root
    get "dashboard", to: "dashboard#index", as: :dashboard
    
    resources :sections do
      resources :section_contents, only: [:new, :create, :edit, :update, :destroy] do
        member do
          patch :activate
        end
      end
    end
    
    resources :articles do
      member do
        patch :publish
        patch :unpublish
      end
      # 本文内画像アップロード用
      resources :images, only: [:create], controller: 'article_images'
    end
    
    resources :categories do
      member do
        patch :move_up
        patch :move_down
      end
    end
    
    resources :tags
    
    resources :my_story_sections do
      member do
        patch :move_up
        patch :move_down
        patch :toggle_active
      end
    end
  end
  
  # Public routes
  root "portfolio#index"
  
  # Blog routes
  get "blog", to: "blog#index", as: :blog
  get "blog/:slug", to: "blog#show", as: :blog_article
  
  # My Story route
  get "my-story", to: "my_story#index", as: :my_story
  
  # Public API routes
  namespace :api do
    namespace :v1 do
      # Articles API
      resources :articles, only: [:index, :show], param: :slug do
        collection do
          get :search
        end
      end
      
      # Categories API
      resources :categories, only: [:index, :show] do
        member do
          get :articles
        end
      end
      
      # Tags API
      resources :tags, only: [:index, :show] do
        member do
          get :articles
        end
      end
      
      # Sections API (Portfolio content)
      resources :sections, only: [:index, :show], param: :name
      
      # API info endpoint
      get '', to: 'base#info'
    end
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
