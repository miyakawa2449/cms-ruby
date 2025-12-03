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
  
  # Public routes (to be implemented)
  root "portfolio#index"
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
