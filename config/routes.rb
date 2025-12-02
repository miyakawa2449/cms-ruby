Rails.application.routes.draw do
  # ========================================
  # SYSTEM HEALTH & PWA ROUTES
  # ========================================
  
  # Health check for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check
  
  # PWA files (Progressive Web App support)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ========================================
  # FRONTEND ROUTES (PUBLIC SITE)
  # ========================================
  
  # Root route - Portfolio top page (縦スクロール型ポートフォリオ)
  root "pages#portfolio"
  
  # Portfolio pages  
  get "my-story", to: "pages#my_story", as: :my_story
  
  # Contact form (Slack integration)
  post "contact", to: "portfolio#contact", as: :contact
  
  # Blog routes (public)
  get "blog", to: "blog#index", as: :blog                    # /blog
  get "blog/category/:slug", to: "blog#category", as: :blog_category  # /blog/category/ai-ml
  get "blog/article/:slug", to: "blog#article", as: :blog_article     # /blog/article/chatgpt-rails
  
  # For future expansion - search functionality
  get "blog/search", to: "blog#search", as: :blog_search
  
  # RSS and Sitemap (public)
  get "feed.rss", to: "feed#rss", as: :rss_feed, defaults: { format: "xml" }
  get "sitemap.xml", to: "sitemap#index", as: :sitemap, defaults: { format: "xml" }
  get "robots.txt", to: "sitemap#robots", as: :robots, defaults: { format: "text" }

  # ========================================
  # ADMIN ROUTES (MANAGEMENT INTERFACE)
  # ========================================
  
  # Dynamic admin path (configurable via environment variable)
  admin_path = ENV.fetch("ADMIN_PATH", "admin")
  
  scope path: admin_path, module: :admin, as: :admin do
    # Authentication (Devise)
    devise_for :admin_users, path: "auth", controllers: {
      sessions: "admin/auth/sessions",
      passwords: "admin/auth/passwords"
    }
    
    # Admin dashboard root
    get "/", to: "dashboard#index", as: :root
    get "dashboard", to: "dashboard#index", as: :dashboard
    
    # Article management (blog CMS)
    resources :articles do
      member do
        patch :publish
        patch :unpublish
        patch :archive
        post :duplicate
        get :preview
      end
      
      collection do
        get :drafts
        get :published
        get :archived
        patch :bulk_update
        delete :bulk_destroy
      end
      
      # AI processing routes
      scope :ai, module: :ai do
        post :analyze, to: "analysis#create"
        get :analyze, to: "analysis#show"
        post :suggest_tags, to: "suggestions#tags"
        post :suggest_categories, to: "suggestions#categories"
        post :generate_summary, to: "content#summary"
        post :optimize_seo, to: "seo#optimize"
      end
    end
    
    # Category management (2-level hierarchy)
    resources :categories do
      member do
        post :move_up
        post :move_down
      end
      collection do
        post :sort
      end
      resources :subcategories, controller: :categories
    end
    
    # Tag management
    resources :tags do
      collection do
        get :autocomplete
        post :merge
      end
    end
    
    # Comment management
    resources :comments, only: [:index, :show, :update, :destroy] do
      member do
        patch :approve
        patch :reject
        patch :spam
      end
      collection do
        get :pending
        get :approved
        get :spam
        patch :bulk_moderate
      end
    end
    
    # Media library management
    resources :media_files, path: :media do
      collection do
        post :upload
        post :bulk_upload
        get :usage_stats
      end
      member do
        post :optimize
        get :usage
      end
    end
    
    # Portfolio CMS (8 sections)
    resources :portfolio_sections, path: :portfolio do
      member do
        post :move_up
        post :move_down
        patch :toggle_visibility
      end
      collection do
        post :sort
        get :preview
      end
    end
    
    # User management (admin users)
    resources :admin_users, path: :users do
      member do
        patch :activate
        patch :deactivate
        post :reset_password
      end
    end
    
    # System settings (8 tabs)
    namespace :settings do
      get "/", to: "general#index", as: :root
      
      # General settings tab
      resource :general, only: [:show, :update] do
        patch :maintenance_mode
      end
      
      # SEO settings tab
      resource :seo, only: [:show, :update] do
        post :generate_sitemap
        post :submit_sitemap
      end
      
      # AI integration settings tab
      resource :ai, only: [:show, :update] do
        post :test_connection
        get :usage_stats
      end
      
      # Security settings tab
      resource :security, only: [:show, :update] do
        post :change_admin_path
        get :login_logs
        post :clear_sessions
      end
      
      # External integrations tab
      resource :integrations, only: [:show, :update] do
        post :test_slack
        post :test_email
      end
      
      # Email settings tab
      resource :email, only: [:show, :update] do
        post :test_smtp
      end
      
      # Backup settings tab
      resource :backup, only: [:show, :update] do
        post :create_backup
        get :restore
        post :restore
      end
      
      # Monitoring settings tab
      resource :monitoring, only: [:show, :update] do
        get :system_status
        get :performance_metrics
        get :error_logs
      end
    end
    
    # Analytics and reports
    namespace :analytics do
      get "/", to: "dashboard#index", as: :root
      get "traffic", to: "traffic#index"
      get "content", to: "content#index"
      get "performance", to: "performance#index"
      get "export", to: "export#index"
      post "export", to: "export#create"
    end
  end

  # ========================================
  # API ROUTES
  # ========================================

  # API versioning with namespace
  namespace :api do
    # ========================================
    # PUBLIC API (v1) - External consumption
    # ========================================
    namespace :v1 do
      # API health and info
      get "health", to: "health#show"
      get "info", to: "info#show"
      
      # Blog articles API (public read-only)
      resources :articles, only: [:index, :show] do
        collection do
          get :featured
          get :recent
        end
      end
      
      # Categories and tags (public read-only)
      resources :categories, only: [:index, :show] do
        resources :articles, only: [:index], controller: "category_articles"
      end
      
      resources :tags, only: [:index, :show] do
        resources :articles, only: [:index], controller: "tag_articles"
      end
      
      # Portfolio sections API (public read-only)
      resources :portfolio_sections, path: :portfolio, only: [:index, :show]
      
      # Search API
      namespace :search do
        get "/", to: "articles#index", as: :articles
        get "suggestions", to: "suggestions#index"
        get "autocomplete", to: "autocomplete#index"
      end
      
      # Contact form API (with reCAPTCHA)
      post "contact", to: "contact#create"
      
      # RSS and feeds
      get "feed", to: "feed#articles", defaults: { format: :json }
      get "sitemap", to: "sitemap#index", defaults: { format: :json }
      
      # Media files (public read-only)
      resources :media_files, path: :media, only: [:show] do
        member do
          get :download
          get :thumbnail
        end
      end
    end
    
    # ========================================
    # INTERNAL API - Admin/CMS operations
    # ========================================
    namespace :internal do
      # Article management API
      resources :articles do
        member do
          patch :publish
          patch :unpublish
          patch :archive
          post :duplicate
        end
        
        collection do
          get :drafts
          get :published
          get :archived
          patch :bulk_update
          delete :bulk_destroy
        end
      end
      
      # AI processing API
      namespace :ai do
        post "analyze/:article_id", to: "analysis#create", as: :analyze_article
        get "analyze/:article_id", to: "analysis#show", as: :analysis_result
        post "suggest/tags", to: "suggestions#tags"
        post "suggest/categories", to: "suggestions#categories"
        post "generate/summary", to: "content#summary"
        post "optimize/seo", to: "seo#optimize"
        get "usage", to: "usage#index"
      end
      
      # Media management API
      resources :media_files, path: :media do
        collection do
          post :upload
          post :bulk_upload
          get :usage_stats
        end
        member do
          post :optimize
          get :usage
          delete :destroy
        end
      end
      
      # Category and tag management API
      resources :categories do
        collection do
          post :sort
        end
        member do
          post :move_up
          post :move_down
        end
      end
      
      resources :tags do
        collection do
          get :autocomplete
          post :merge
        end
      end
      
      # Portfolio CMS API
      resources :portfolio_sections, path: :portfolio do
        collection do
          post :sort
        end
        member do
          post :move_up
          post :move_down
          patch :toggle_visibility
        end
      end
      
      # Analytics API
      namespace :analytics do
        get "dashboard", to: "dashboard#index"
        get "traffic", to: "traffic#index"
        get "content", to: "content#stats"
        get "performance", to: "performance#metrics"
        get "export", to: "export#data"
      end
      
      # System settings API
      namespace :settings do
        resources :general, only: [:show, :update]
        resources :seo, only: [:show, :update]
        resources :ai, only: [:show, :update]
        resources :security, only: [:show, :update]
        resources :integrations, only: [:show, :update]
        resources :email, only: [:show, :update]
        resources :backup, only: [:show, :update]
        resources :monitoring, only: [:show, :update]
      end
    end
  end

  # ========================================
  # SIDEKIQ WEB INTERFACE (DEVELOPMENT)
  # ========================================
  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end

  # ========================================
  # DEVELOPMENT TOOLS
  # ========================================
  if Rails.env.development?
    # Letter Opener (email preview)
    mount LetterOpenerWeb::Engine, at: "/letter_opener" if defined?(LetterOpenerWeb)
  end
  
  # Catch-all route for 404s (must be last)
  match "*path", to: "application#not_found", via: :all, constraints: lambda { |req|
    !req.path.starts_with?("/rails/") && !req.path.starts_with?("/assets/")
  }
end
