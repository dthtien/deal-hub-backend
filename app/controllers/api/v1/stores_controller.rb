# frozen_string_literal: true

module Api
  module V1
    class StoresController < ApplicationController
      PER_PAGE = 20

      def trending
        data = Rails.cache.fetch('stores_trending_v1', expires_in: 30.minutes) do
          results = ClickTracking
            .where('created_at >= ?', 24.hours.ago)
            .where.not(store: [nil, ''])
            .group(:store)
            .order('COUNT(*) DESC')
            .limit(5)
            .count

          results.map do |store, count|
            {
              name: store,
              click_count: count,
              favicon_url: "https://www.google.com/s2/favicons?domain=#{store.downcase.gsub(/\s+/, '').concat('.com.au')}&sz=64"
            }
          end
        end

        render json: { stores: data }
      end

      def index
        response.set_header('Cache-Control', 'public, max-age=3600')

        stores = Rails.cache.fetch('stores_index_v2', expires_in: 1.hour) do
          # Aggregate deal_count and avg_discount for all stores in one query
          stats = Product.where(expired: false)
                         .group(:store)
                         .select(
                           :store,
                           'COUNT(*) AS deal_count',
                           'ROUND(AVG(CASE WHEN discount > 0 THEN discount ELSE NULL END)::numeric, 1) AS avg_discount'
                         )
                         .index_by(&:store)

          # Aggregate review stats per store in one query
          review_stats = StoreReview
            .group(:store_name)
            .select(:store_name, 'ROUND(AVG(rating)::numeric,1) AS avg_rating', 'COUNT(*) AS review_count')
            .index_by(&:store_name)

          Product::STORES.map do |store|
            row    = stats[store]
            dc     = row&.deal_count.to_i
            avg    = row&.avg_discount.to_f.round(1)
            best   = Product.where(store: store, expired: false).order(discount: :desc).first
            rrow   = review_stats[store]

            {
              name:         store,
              deal_count:   dc,
              avg_discount: avg,
              best_deal:    best&.as_json,
              avg_rating:   rrow&.avg_rating.to_f,
              review_count: rrow&.review_count.to_i
            }
          end
        end

        render json: { stores: stores }
      end

      def compare
        store_names = Array(params[:stores]).first(3).map { |s| URI.decode_www_form_component(s.to_s) }
        if store_names.size < 2
          return render json: { error: 'Provide 2-3 store names' }, status: :unprocessable_entity
        end

        result = store_names.map do |store|
          products = Product.where(store: store, expired: false)
          total = products.count
          avg_discount = products.where('discount > 0').average(:discount)&.to_f&.round(1) || 0.0
          best = products.order(discount: :desc).first
          prices = products.where('price IS NOT NULL').pluck(:price).map(&:to_f)
          {
            store: store,
            total_deals: total,
            avg_discount: avg_discount,
            best_deal: best&.as_json,
            price_range: prices.any? ? { min: prices.min.round(2), max: prices.max.round(2) } : nil
          }
        end

        render json: { comparison: result }
      end

      def inventory
        store_name = URI.decode_www_form_component(params[:name])
        products = Product.where(store: store_name)
        total = products.count

        if total.zero?
          return render json: {
            total_products: 0,
            in_stock: 0,
            out_of_stock: 0,
            stock_rate: 0.0
          }
        end

        in_stock = products.where(in_stock: true).count
        out_of_stock = total - in_stock
        stock_rate = (in_stock.to_f / total * 100).round(1)

        render json: {
          total_products: total,
          in_stock:       in_stock,
          out_of_stock:   out_of_stock,
          stock_rate:     stock_rate
        }
      end

      def deals
        store_name = URI.decode_www_form_component(params[:name])
        page = (params[:page] || 1).to_i
        offset = (page - 1) * PER_PAGE

        base = Product.where(store: store_name).order(discount: :desc, created_at: :desc)
        total = base.count
        products = base.limit(PER_PAGE).offset(offset)

        # Store stats
        all_store_products = Product.where(store: store_name)
        total_deals = all_store_products.count
        avg_discount = all_store_products.where('discount > 0').average(:discount)&.round || 0
        top_category = all_store_products
          .where("categories IS NOT NULL AND array_length(categories, 1) > 0")
          .pluck(:categories)
          .flatten
          .tally
          .max_by { |_, v| v }
          &.first || 'General'

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page: page,
            total_count: total,
            total_pages: (total.to_f / PER_PAGE).ceil,
            show_next_page: offset + PER_PAGE < total
          },
          store_stats: {
            total_deals: total_deals,
            avg_discount: avg_discount,
            top_category: top_category
          }
        }
      end
    end
  end
end
