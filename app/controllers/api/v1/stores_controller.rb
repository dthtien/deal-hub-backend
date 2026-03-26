# frozen_string_literal: true

module Api
  module V1
    class StoresController < ApplicationController
      PER_PAGE = 20

      def index
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
