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
          # Admin-only stats
          total_active_products: total_count,
          total_subscribers:     Subscriber.count,
          clicks_today:          clicks_today
        }
      end
    end
  end
end
