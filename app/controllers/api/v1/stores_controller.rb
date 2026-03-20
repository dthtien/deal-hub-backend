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

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page: page,
            total_count: total,
            total_pages: (total.to_f / PER_PAGE).ceil,
            show_next_page: offset + PER_PAGE < total
          }
        }
      end
    end
  end
end
