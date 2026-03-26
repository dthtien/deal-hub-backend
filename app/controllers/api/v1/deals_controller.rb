module Api
  module V1
    class DealsController < ApplicationController
      def index
        service = Deals::Index.call(params)

        render json: {
          products: service.paginate.collection,
          metadata: service.paginate.metadata
        }
      end

      def featured
        products = Product.includes(:ai_deal_analysis)
                          .where(featured: true, expired: false)
                          .order(updated_at: :desc)
                          .limit(10)
        render json: { products: products }
      end

      def personalised
        stores     = Array(params[:stores]).first(5).map(&:to_s)
        categories = Array(params[:categories]).first(5).map(&:to_s)

        products = Product.includes(:ai_deal_analysis).where(expired: false)

        if stores.any? || categories.any?
          store_scope    = stores.any?     ? Product.where(store: stores)                                              : Product.none
          category_scope = categories.any? ? Product.where('categories && array[?]::varchar[]', categories)           : Product.none
          products = products.merge(store_scope.or(category_scope))
        end

        products = products.where('discount > 0')
                           .order(deal_score: :desc, discount: :desc)
                           .limit(8)

        render json: { products: products }
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

      def best_drops
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        dropped_ids = PriceHistory
          .where('recorded_at >= ?', 24.hours.ago)
          .where('old_price > price')
          .distinct
          .pluck(:product_id)

        base = Product
          .where(id: dropped_ids, expired: false)
          .where('discount > 0')
          .order(discount: :desc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def new_today
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product
          .where(expired: false)
          .where('products.created_at >= ?', 24.hours.ago)
          .order(created_at: :desc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def expiring_soon
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product
          .where(expired: false)
          .where('expires_at IS NOT NULL AND expires_at > ? AND expires_at <= ?', Time.current, 48.hours.from_now)
          .order(expires_at: :asc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def this_week
        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base = Product
          .where(expired: false)
          .where('products.created_at >= ?', 7.days.ago)
          .order(deal_score: :desc)

        total    = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page:           page,
            per_page:       per_page,
            total_count:    total,
            total_pages:    (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end

      def deal_of_the_week
        deal = Rails.cache.fetch("deal_of_the_week_#{Date.today.beginning_of_week}", expires_in: 7.days) do
          Product.where(expired: false)
                 .where('products.created_at >= ?', 7.days.ago)
                 .where.not(image_url: [nil, ''])
                 .order(deal_score: :desc)
                 .first
        end

        if deal
          render json: deal.as_json
        else
          render json: nil
        end
      end

      def deal_of_the_day
        deal = Rails.cache.fetch("deal_of_the_day_#{Date.today}", expires_in: 24.hours) do
          Product.where(expired: false)
                 .where('discount > 20')
                 .where.not(image_url: [nil, ''])
                 .order(deal_score: :desc, discount: :desc)
                 .first
        end

        if deal
          render json: deal.as_json
        else
          render json: nil
        end
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
