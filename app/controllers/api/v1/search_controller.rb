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
