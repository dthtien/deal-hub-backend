module Api
  module V1
    class DealsController < ApplicationController
      def index
        service = Deals::Index.call(params.merge(exclude_count: true))

        render json: {
          products: service.paginate.collection,
          metadata: service.paginate.metadata
        }
      end

      def show
        product = Product.find(params[:id])
        render json: product
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def trending
        # Top clicked products in last 7 days
        trending = ClickTracking
          .where(clicked_at: 7.days.ago..)
          .joins(:product)
          .select('products.*, COUNT(click_trackings.id) as click_count')
          .group('products.id')
          .order('click_count DESC')
          .limit(10)

        render json: { products: trending }
      end

      def redirect
        product = Product.find(params[:id])

        ClickTracking.create!(
          product_id: product.id,
          store: product.store,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          referrer: request.referer,
          clicked_at: Time.current
        )

        affiliate_url = AffiliateUrlService.call(product)

        render json: {
          affiliate_url: affiliate_url,
          click_count: product.click_count
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Product not found' }, status: :not_found
      end
    end
  end
end
