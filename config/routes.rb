Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    resources :affiliate_configs
  end

  namespace :api do
    namespace :v1 do
      resources :deals, only: :index
      resource :metadata, only: :show
      resources :price_alerts, only: :create
      resources :affiliate_configs, only: :index
      resources :products, only: [] do
        get :price_history, on: :member
      end
      namespace :insurances do
        resources :quotes, only: %w[create show]
        resources :addresses, only: :index
        resources :car_registers, only: :index
      end
    end
  end
end
