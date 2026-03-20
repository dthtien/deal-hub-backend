# frozen_string_literal: true

module Api
  module V1
    class PriceHistoriesController < ApplicationController
      def index
        product = Product.find(params[:deal_id])
        histories = product.price_histories.recent.limit(30)

        render json: {
          price_histories: histories.map { |h|
            {
              price: h.price,
              old_price: h.old_price,
              discount: h.discount,
              recorded_at: h.recorded_at
            }
          }
        }
      end
    end
  end
end
