Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "sitemap.xml"       => "sitemap#index",         defaults: { format: :xml }
  get "sitemap_index.xml" => "sitemap#sitemap_index", defaults: { format: :xml }
  get "sitemap_deals.xml" => "sitemap#sitemap_deals", defaults: { format: :xml }
  get "sitemap_stores.xml"=> "sitemap#sitemap_stores",defaults: { format: :xml }
  get "r/:code" => "referrals#redirect", as: :referral_redirect
  get "feed.xml"    => "feed#index"
  get "robots.txt"  => "robots#index", defaults: { format: :text }

  # Admin
  namespace :admin do
    root to: 'dashboard#index'
    scope '/export', controller: :exports do
      get 'products.csv',     action: :products,     as: :export_products
      get 'subscribers.csv',  action: :subscribers,  as: :export_subscribers
      get 'coupons.csv',      action: :coupons,      as: :export_coupons
    end
    resources :products, only: %i[index update] do
      member do
        post :mark_flash
      end
      collection do
        post :bulk_update
        post :bulk_action
        post :bulk_expire
      end
    end
    resources :coupons do
      collection do
        get  :import
        post :import
      end
    end
    resources :deal_submissions, only: %i[index show destroy] do
      member do
        post :approve
        post :reject
      end
    end
    resources :coupon_submissions, only: %i[index] do
      member do
        post :approve
        post :reject
      end
    end
    resources :deal_reports, only: %i[index] do
      member do
        post :dismiss
        post :expire_deal
      end
    end
    resources :webhooks, only: %i[index create destroy]
    resources :crawlers, only: %i[index]
    resources :crawl_logs, only: %i[index]
    get 'analytics', to: 'analytics#index'
    get 'analytics/click_heatmap', to: 'analytics#click_heatmap', as: :admin_click_heatmap
    get 'analytics/affiliate', to: 'analytics#affiliate', as: :admin_affiliate_analytics
    get 'reports/stores', to: 'reports#stores', as: :admin_reports_stores
    get 'search', to: 'search#index'
    resources :notification_logs, only: %i[index]
    resources :subscribers, only: %i[index] do
      member do
        post :unsubscribe
      end
      collection do
        post :import
      end
    end
  end

  # Google OAuth
  get '/auth/google_oauth2/callback', to: 'auth#google_callback'
  get '/auth/failure', to: redirect('/?auth_error=access_denied')

  namespace :api do
    namespace :v1 do
      get  '/auth/me', to: 'auth#me'
    end
  end
  get "merchant_feed.xml" => "merchant_feed#index", defaults: { format: :xml }


  namespace :api do
    namespace :v2 do
      resources :deals, only: %i[index show]
    end
  end

  namespace :api do
    namespace :v1 do
      post 'auth/signup', to: 'auth#signup'
      post 'auth/login', to: 'auth#login'
      get  'auth/me', to: 'auth#me'
      resources :saved_deals, only: %i[index create destroy]
      get 'deals/deal_of_the_month', to: 'deals#deal_of_the_month'
      get 'deals/biggest_drops', to: 'deals#biggest_drops'
      get 'deals/high_quality', to: 'deals#high_quality'
      get 'deals/top_picks', to: 'deals#top_picks'
      get 'deals/freshness_stats', to: 'deals#freshness_stats'
      get 'tags', to: 'tags#index'
      get 'deals/hot', to: 'deals#hot'
      get 'deals/fresh', to: 'deals#fresh'
      get 'deals/deal_of_the_day', to: 'deals#deal_of_the_day'
      get 'deals/past_deals_of_day', to: 'deals#past_deals_of_day'
      get 'deals/deal_of_the_week', to: 'deals#deal_of_the_week'
      get 'deals/flash', to: 'deals#flash_deals'
      get 'deals/compare', to: 'deals#compare'
      get 'deals/bundles', to: 'deals#bundles'
      get 'exchange_rates', to: 'exchange_rates#index'
      resources :store_follows, only: %i[index create destroy] do
        collection do
          get :deals
        end
      end
      get 'trending_searches', to: 'trending_searches#index'
      resources :deals, only: %i[index show] do
        member do
          get :redirect
          get :similar
          get :recommendations
          get :engagement
          post :view
          post :report
          get :ai_summary
          get :meta
          post :share
          get :price_prediction
        end
        collection do
          get :trending
          get :featured
          get :new_today
          get :best_drops
          get :expiring_soon
          get :personalised
          get :recommended
          get :this_week
          get :deal_of_the_week
          get :most_shared
        end
        resources :price_histories, only: :index
        resources :price_alerts, only: :create
        resources :comments, only: %i[index create]
        resource :analysis, only: :show, controller: 'deal_analyses'
        resource :vote, only: %i[show create], controller: 'votes'
        resource :rating, only: %i[show create], controller: 'deal_ratings'
      end
      resources :collections, only: %i[index show], param: :slug
      resource :metadata, only: :show
      resources :coupons, only: %i[index] do
        collection do
          get :stores
          post ':code/track_use', to: 'coupons#track_use', as: :track_use
          get ':code/validate', to: 'coupons#validate', as: :validate_coupon
        end
        member do
          post :use
        end
      end
      get 'categories', to: 'categories#index'
      get 'categories/:name/top_deals', to: 'categories#top_deals', as: :category_top_deals
      post 'category_alerts', to: 'category_alerts#create'
      delete 'category_alerts', to: 'category_alerts#destroy'
      get 'analytics/clicks', to: 'analytics#clicks'
      resources :deal_submissions, only: :create
      resources :coupon_submissions, only: :create
      resources :subscribers, only: %i[create index] do
        collection { get :unsubscribe }
        member do
          patch :update_preferences
          patch :resubscribe
        end
      end
      namespace :admin do
        resources :store_stats, only: :index
        get 'crawler_health', to: 'crawler_health#index'
      end
      resources :push_subscriptions, only: %i[create destroy]
      resource :leaderboard, only: :show
      resources :search, only: [] do
        collection do
          get :suggestions
          post :track
          get :analytics
        end
      end
      resources :keyword_alerts, only: :create
      resources :stores, only: :index do
        collection do
          get 'trending', to: 'stores#trending'
          get ':name/deals', to: 'stores#deals', as: :store_deals
          get 'compare', to: 'stores#compare'
          get ':store_name/reviews', to: 'store_reviews#index', as: :store_reviews
          post ':store_name/reviews', to: 'store_reviews#create', as: :create_store_review
        end
      end
      resources :price_alerts, only: %i[destroy index] do
        collection do
          post :bulk
        end
      end
      get 'activity', to: 'activity#index'
      get  'preferences', to: 'preferences#show'
      post 'preferences', to: 'preferences#create'
      get  'brands', to: 'brands#index'
      get  'brands/:name/deals', to: 'brands#deals', as: :brand_deals, constraints: { name: /[^\/]+/ }
      namespace :referrals do
      end
      get 'referrals/link', to: 'referrals#link'
      namespace :insurances do
        resources :quotes, only: %w[create show]
        resources :addresses, only: :index
        resources :car_registers, only: :index
      end
    end
  end
end
