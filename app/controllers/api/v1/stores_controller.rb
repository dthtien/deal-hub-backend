# frozen_string_literal: true

module Api
  module V1
    class StoresController < ApplicationController
      PER_PAGE = 20

      def index
        response.set_header('Cache-Control', 'public, max-age=3600')
        stores = Product::STORES.map do |store|
          products = Product.where(store: store)
          best = products.order(discount: :desc).first

          {
            name: store,
            deal_count: products.count,
            best_deal: best&.as_json
          }
        end

        render json: stores
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
