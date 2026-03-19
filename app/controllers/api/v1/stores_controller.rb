# frozen_string_literal: true

module Api
  module V1
    class StoresController < ApplicationController
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
        products = Product.where(store: store_name)
                          .order(discount: :desc)

        render json: {
          store: store_name,
          meta: {
            title: "Best #{store_name} Deals in Australia | OzVFY",
            description: "Find the best #{store_name} deals and discounts in Australia. Updated daily."
          },
          total: products.count,
          deals: products.map(&:as_json)
        }
      end
    end
  end
end
