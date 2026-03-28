module Api
  module V1
    class MetadataController < ApplicationController
      def show
        service = Deals::Index.new(params, with_order: false)
        service.call

        active = Product.where(expired: false)
        total_count  = active.count
        stores_count = active.distinct.count(:store)
        avg_discount = active.where('discount > 0').average(:discount)&.to_f&.round(1) || 0.0
        new_today    = active.where('products.created_at >= ?', 24.hours.ago).count
        hot_count    = active.where('deal_score >= ?', 80).count

        clicks_today = ClickTracking.where('clicked_at >= ?', Time.current.beginning_of_day).count rescue 0

        best_discount      = active.where('discount > 0').maximum(:discount)&.to_f&.round(1) || 0.0
        newest_store       = active.order(created_at: :desc).limit(1).pluck(:store).first
        total_brands       = active.where.not(brand: [nil, '']).distinct.count(:brand)
        deals_expiring_today = Product.where(expired: false)
                                      .where('products.created_at >= ?', Time.current)
                                      .count rescue 0

        render json: {
          brands:           service.products.brands,
          categories:       service.products.categories,
          stores:           service.products.stores,
          subscriber_count: Subscriber.count,
          total_count:      total_count,
          stores_count:     stores_count,
          avg_discount:     avg_discount,
          new_today:        new_today,
          hot_count:        hot_count,
          best_discount:    best_discount,
          newest_store:     newest_store,
          total_brands:     total_brands,
          deals_expiring_today: deals_expiring_today,
          # Admin-only stats
          total_active_products: total_count,
          total_subscribers:     Subscriber.count,
          clicks_today:          clicks_today
        }
      end
    end
  end
end
