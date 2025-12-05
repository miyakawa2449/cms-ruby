Rails.application.routes.draw do
  devise_for :admin_users, controllers: {
    sessions: 'admin_users/sessions'
  }
  
  # Admin routes
  namespace :admin do
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
    end
    
    resources :categories do
      member do
        patch :move_up
        patch :move_down
      end
    end
    
    resources :tags
  end
  
  # Public routes
  root "portfolio#index"
  
  # Blog routes
  get "blog", to: "blog#index", as: :blog
  get "blog/:slug", to: "blog#show", as: :blog_article
  
  # My Story route
  get "my-story", to: "my_story#index", as: :my_story
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
