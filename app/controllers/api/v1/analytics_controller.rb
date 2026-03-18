module Api
  module V1
    class AnalyticsController < ApplicationController
      def clicks
        top_products = ClickTracking
          .joins(:product)
          .select('products.id, products.name, products.store, products.image_url, COUNT(click_trackings.id) as click_count')
          .group('products.id, products.name, products.store, products.image_url')
          .order('click_count DESC')
          .limit(10)

        by_store = ClickTracking
          .select('store, COUNT(*) as total_clicks')
          .group(:store)
          .order('total_clicks DESC')
          .map { |r| { store: r.store, total_clicks: r.total_clicks } }

        render json: {
          top_products: top_products.map { |p|
            {
              id: p.id,
              name: p.name,
              store: p.store,
              image_url: p.image_url,
              click_count: p.click_count
            }
          },
          by_store: by_store,
          total_clicks: ClickTracking.count
        }
      end
    end
  end
end
