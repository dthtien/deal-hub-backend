# frozen_string_literal: true

module Api
  module V1
    class SearchController < ApplicationController
      POPULAR_PRICE_POINTS = [50, 100, 200].freeze

      def suggestions
        q = params[:q].to_s.strip
        if q.length < 2
          return render json: { products: [], stores: [], categories: [], trending: [] }
        end

        products = Product.where("name ILIKE ?", "%#{q}%")
                          .where(expired: false)
                          .order(deal_score: :desc)
                          .limit(5)
                          .select(:id, :name, :price, :store, :image_url, :discount)

        stores = Product.where("store ILIKE ?", "%#{q}%")
                        .distinct
                        .limit(3)
                        .pluck(:store)
                        .compact

        all_categories = Product.distinct.pluck(:categories).flatten.compact.uniq
        categories = all_categories.select { |c| c.downcase.include?(q.downcase) }.first(3)

        trending = SearchQuery.where("query ILIKE ?", "%#{q}%")
                              .order(count: :desc)
                              .limit(3)
                              .pluck(:query)

        popular_under_price = build_popular_under_price(q)
        new_arrivals = build_new_arrivals(q)

        render json: {
          products: products.map { |d| { id: d.id, name: d.name, price: d.price, store: d.store, image_url: d.image_url, discount: d.discount } },
          stores: stores,
          categories: categories,
          trending: trending,
          popular_under_price: popular_under_price,
          new_arrivals: new_arrivals
        }
      end

      def grouped
        q = params[:q].to_s.strip
        return render json: { products: [], stores: [], categories: [], coupons: [] } if q.length < 2

        wildcard = "%#{q}%"

        products = Product.where("name ILIKE ? OR brand ILIKE ? OR description ILIKE ?", wildcard, wildcard, wildcard)
                          .where(expired: false)
                          .order(deal_score: :desc)
                          .limit(20)
                          .map { |p| p.as_json.slice('id', 'name', 'price', 'store', 'discount', 'image_url', 'optimized_image_url', 'discount_tier') }

        store_names = Product.where("store ILIKE ?", wildcard)
                             .distinct
                             .limit(5)
                             .pluck(:store)
                             .compact

        stores = store_names.map do |name|
          count = Product.where(store: name, expired: false).count
          avg_disc = Product.where(store: name, expired: false).average(:discount)&.to_f&.round(1) || 0.0
          { name: name, deal_count: count, avg_discount: avg_disc }
        end

        all_cats = Product.distinct.pluck(:categories).flatten.compact.uniq
        matching_cats = all_cats.select { |c| c.downcase.include?(q.downcase) }.first(5)
        categories = matching_cats.map do |cat|
          count = Product.where("? = ANY(categories)", cat).where(expired: false).count
          { name: cat, deal_count: count }
        end

        coupons = Coupon.active
                        .where("code ILIKE ? OR store ILIKE ? OR description ILIKE ?", wildcard, wildcard, wildcard)
                        .order(verified: :desc, use_count: :desc)
                        .limit(5)
                        .map { |c| { id: c.id, code: c.code, store: c.store, description: c.description, discount_label: c.discount_label, expires_at: c.expires_at } }

        render json: {
          products: products,
          stores: stores,
          categories: categories,
          coupons: coupons
        }
      end

      def track
        query = params[:query].to_s.strip
        result_count = params[:result_count].to_i
        clicked_product_id = params[:clicked_product_id]

        if query.length >= 2
          SearchQuery.track(query, result_count: result_count)
        end

        render json: { ok: true }
      end

      def analytics
        unless current_user&.admin?
          return render json: { error: 'Unauthorized' }, status: :unauthorized
        end

        queries = SearchQuery.order(count: :desc).limit(50)

        render json: queries.map { |q|
          {
            query: q.query,
            count: q.count,
            avg_result_count: q.avg_result_count
          }
        }
      end

      private

      def build_popular_under_price(q)
        POPULAR_PRICE_POINTS.filter_map do |price_point|
          deal = Product.where("name ILIKE ?", "%#{q}%")
                        .where(expired: false)
                        .where('price <= ?', price_point)
                        .where('discount > 0')
                        .order(discount: :desc)
                        .select(:id, :name, :price, :store, :discount)
                        .first
          next unless deal
          { price_point: price_point, id: deal.id, name: deal.name, price: deal.price, store: deal.store, discount: deal.discount }
        end.first(3)
      end

      def build_new_arrivals(q)
        Product.where("name ILIKE ?", "%#{q}%")
               .where(expired: false)
               .order(created_at: :desc)
               .limit(2)
               .select(:id, :name, :price, :store, :image_url, :created_at)
               .map { |d| { id: d.id, name: d.name, price: d.price, store: d.store, image_url: d.image_url, created_at: d.created_at } }
      end
    end
  end
end
