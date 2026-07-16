Rails.application.routes.draw do
  admin_path = AdminPath::Resolver.current_path
  # ルート構築時のパスを記録（AdminPathRouteReloaderが変更検知に使う）
  AdminPathRouteReloader.active_path = admin_path
  # SEO関連
  get "/sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }
  get "/feed.rss", to: "feeds#rss", defaults: { format: "rss" }, as: :feed_rss
  get "/feed.atom", to: "feeds#atom", defaults: { format: "atom" }, as: :feed_atom

  # Contact form submission
  post "contacts", to: "contacts#create"
  # NOTE: registrations skipped for security (single-user CMS)
  # Future: Remove skip when implementing multi-tenant CMS sales version
  devise_for :admin_users, path: admin_path,
    skip: [ :registrations ],
    controllers: { sessions: "admin_users/sessions" }

  # Admin routes (セキュリティのため長いURL使用)
  namespace :admin, path: admin_path do
    resource :site_settings, only: [ :show, :update ]
    resources :contacts, only: [ :index, :show, :update, :destroy ]
    root to: "dashboard#index", as: :root
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Two-Factor Authentication
    resource :two_factor_auth, only: [ :show, :new, :create, :destroy ], controller: "two_factor_auth" do
      post :regenerate_backup_codes
    end

    resources :sections do
      resources :section_contents, only: [ :new, :create, :edit, :update, :destroy ] do
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
      resources :images, only: [ :create ], controller: "article_images"
      # AI支援機能
      namespace :ai do
        post "suggest_title", action: :suggest_title, controller: "/admin/ai"
        post "generate_summary", action: :generate_summary, controller: "/admin/ai"
        post "suggest_tags", action: :suggest_tags, controller: "/admin/ai"
        post "generate_slug", action: :generate_slug, controller: "/admin/ai"
        post "generate_seo_meta", action: :generate_seo_meta, controller: "/admin/ai"
      end
    end

    # AI機能（記事に紐づかないもの）
    scope "ai", as: "ai" do
      post "suggest_structure", to: "ai#suggest_structure"
      get "usage_stats", to: "ai#usage_stats"
    end

    # AI使用統計
    resources :ai_usage, only: [ :index ] do
      collection do
        get :export
      end
    end

    resources :categories do
      member do
        patch :move_up
        patch :move_down
      end
    end

    resources :tags

    # Media library
    resources :media, only: [ :index, :show, :create, :update, :destroy ] do
      member do
        post :edit_image
        get :usage
      end
      collection do
        delete :bulk_destroy
      end
    end

    # 管理画面URL管理
    resource :admin_path_settings, only: [ :edit, :update ] do
      post :emergency_rotation, on: :collection
    end

    # Database export/import
    resource :database, only: [], controller: "database" do
      collection do
        get :export
        get :import_form
        post :import
      end
    end

    # Security audit (Phase 7.4)
    resources :security_scans, only: [ :index, :show ]
    resources :security_reports, only: [ :index, :show ] do
      member do
        get :download
      end
    end

    # Backup management (Phase 7.3)
    resources :backups, only: [ :index ] do
      collection do
        post :restore
      end
    end
  end

  # Public routes
  root "portfolio#index"

  # Blog routes
  get "blog", to: "blog#index", as: :blog
  get "blog/:slug", to: "blog#show", as: :blog_article

  # 旧My Story独立ページ（廃止済み）からトップページの同名セクションへ恒久リダイレクト
  get "my-story", to: redirect("/#my-story", status: 301)

  # Public API routes
  namespace :api do
    namespace :v1 do
      # Articles API
      resources :articles, only: [ :index, :show ], param: :slug do
        collection do
          get :search
        end
      end

      # Categories API
      resources :categories, only: [ :index, :show ] do
        member do
          get :articles
        end
      end

      # Tags API
      resources :tags, only: [ :index, :show ] do
        member do
          get :articles
        end
      end

      # Sections API (Portfolio content)
      resources :sections, only: [ :index, :show ], param: :name

      # API info endpoint
      get "", to: "base#info"
    end

    # Internal API routes (GitHub Actions integration)
    namespace :internal do
      resource :security, only: [], controller: "security" do
        post :brakeman
        post :bundler_audit
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
