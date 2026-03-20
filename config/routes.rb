Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "sitemap.xml" => "sitemap#index", defaults: { format: :xml }


  namespace :api do
    namespace :v1 do
      post 'auth/signup', to: 'auth#signup'
      post 'auth/login', to: 'auth#login'
      get  'auth/me', to: 'auth#me'
      resources :saved_deals, only: %i[index create destroy]
      resources :deals, only: %i[index show] do
        member do
          get :redirect
        end
        collection do
          get :trending
        end
      end
      resource :metadata, only: :show
      get 'analytics/clicks', to: 'analytics#clicks'
      resources :subscribers, only: %i[create index]
      resources :stores, only: :index do
        collection do
          get ':name/deals', to: 'stores#deals', as: :store_deals
        end
      end
      resources :deals do
        resources :price_histories, only: :index
        resources :price_alerts, only: :create
        resource :analysis, only: :show, controller: 'deal_analyses'
      end
      namespace :insurances do
        resources :quotes, only: %w[create show]
        resources :addresses, only: :index
        resources :car_registers, only: :index
      end
    end
  end
end
