Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "track/open/:token"  => "track#open",  as: :track_open
  get "track/click/:token" => "track#click", as: :track_click
  get "health" => "health#show"
  get "sitemap.xml"       => "sitemap#index",         defaults: { format: :xml }
  get "sitemap_index.xml" => "sitemap#sitemap_index", defaults: { format: :xml }
  get "sitemap_deals.xml" => "sitemap#sitemap_deals", defaults: { format: :xml }
  get "sitemap_stores.xml"      => "sitemap#sitemap_stores",      defaults: { format: :xml }
  get "sitemap_brands.xml"      => "sitemap#sitemap_brands",      defaults: { format: :xml }
  get "sitemap_collections.xml" => "sitemap#sitemap_collections",  defaults: { format: :xml }
  get "sitemap_categories.xml"  => "sitemap#sitemap_categories",   defaults: { format: :xml }
  get "r/:code" => "referrals#redirect", as: :referral_redirect
  get "feed.xml"              => "feed#index"
  get "stores/:name/feed.xml" => "feed#store", as: :store_feed, constraints: { name: /[^\/]+/ }
  get "robots.txt"  => "robots#index", defaults: { format: :text }

  # GraphQL
  post '/graphql', to: 'graphql#execute'

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
        post :clone
      end
      collection do
        post :bulk_update
        post :bulk_action
        post :bulk_expire
        patch :bulk_update_products
        post :merge
      end
    end
    post 'coupons/generate', to: 'coupon_generate#create', as: :generate_coupons
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
    resources :webhooks, only: %i[index create destroy] do
      member do
        get :deliveries
      end
    end
    resources :crawlers, only: %i[index]
    resources :crawl_logs, only: %i[index]
    get 'crawl_schedule', to: 'crawl_schedule#index'
    get 'analytics', to: 'analytics#index'
    get 'analytics/click_heatmap', to: 'analytics#click_heatmap', as: :admin_click_heatmap
    get 'analytics/affiliate', to: 'analytics#affiliate', as: :admin_affiliate_analytics
    get 'analytics/revenue', to: 'analytics#revenue', as: :admin_revenue_analytics
    get 'analytics/coupons', to: 'analytics#coupons', as: :admin_coupon_analytics
    get 'reports/stores', to: 'reports#stores', as: :admin_reports_stores
    get 'reports/deal_performance', to: 'reports#deal_performance', as: :admin_reports_deal_performance
    get 'search', to: 'search#index'
    resources :api_keys, only: %i[index create destroy]
    get 'dashboard/stats', to: 'dashboard#stats', as: :admin_dashboard_stats
    post 'dashboard/quick_action', to: 'dashboard#quick_action', as: :admin_dashboard_quick_action
    resources :notification_logs, only: %i[index]
    get 'notifications/queue', to: 'notifications#queue', as: :admin_notifications_queue
    get 'notifications',       to: 'system_notifications#index', as: :admin_notifications
    resources :comments, only: %i[index] do
      member do
        post :approve
        post :reject
      end
    end
    resources :subscribers, only: %i[index] do
      member do
        post :unsubscribe
      end
      collection do
        get :export
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
      get 'deals/popular', to: 'deals#popular'
      get 'deals/hot', to: 'deals#hot'
      get 'deals/fresh', to: 'deals#fresh'
      get 'deals/deal_of_the_day', to: 'deals#deal_of_the_day'
      get 'deals/past_deals_of_day', to: 'deals#past_deals_of_day'
      get 'deals/deal_of_the_week', to: 'deals#deal_of_the_week'
      get 'deals/flash', to: 'deals#flash_deals'
      get 'deals/compare', to: 'deals#compare'
      get 'deals/bundles', to: 'deals#bundles'
      get 'deals/price_watch', to: 'deals#price_watch'
      get 'deals/compare_prices', to: 'deals#compare_prices'
      post 'errors', to: 'errors#create'
      get 'exchange_rates', to: 'exchange_rates#index'
      resources :store_follows, only: %i[index create destroy] do
        collection do
          get :deals
        end
      end
      get 'trending_searches', to: 'trending_searches#index'
      get 'trending_keywords', to: 'trending_keywords#index'
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
          get :expiry_prediction
          get :price_analytics
          get :score_history
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
          get :live_feed
        end
        resources :price_histories, only: :index
        resources :price_alerts, only: :create
        resources :comments, only: %i[index create] do
          member do
            post :report
          end
        end
        resource :analysis, only: :show, controller: 'deal_analyses'
        resource :vote, only: %i[show create], controller: 'votes'
        resource :rating, only: %i[show create], controller: 'deal_ratings'
        resource :sentiment, only: :show, controller: 'deal_sentiments'
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
      get 'categories/trending', to: 'categories#trending'
      get 'categories/:name/top_deals', to: 'categories#top_deals', as: :category_top_deals
      resources :comparison_sessions, only: %i[create index]
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
      get 'leaderboard/shares', to: 'leaderboard#shares', as: :leaderboard_shares
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
          get ':name/inventory', to: 'stores#inventory', as: :store_inventory
          get ':name/rating', to: 'stores#rating', as: :store_rating
          get 'compare', to: 'stores#compare'
          get ':store_name/reviews', to: 'store_reviews#index', as: :store_reviews
          post ':store_name/reviews', to: 'store_reviews#create', as: :create_store_review
        end
      end
      resources :price_alerts, only: %i[destroy index] do
        collection do
          post :bulk
          delete :bulk_destroy
          patch :bulk_status
          get :history
        end
      end
      get  'notification_preferences', to: 'notification_preferences#show'
      put  'notification_preferences', to: 'notification_preferences#update'
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
