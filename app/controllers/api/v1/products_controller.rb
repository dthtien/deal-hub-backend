# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      def price_history
        product = Product.find(params[:id])
        history = product.price_histories.recent.chronological

        render json: {
          price_history: history.map { |h| { date: h.recorded_on, price: h.price.to_f } }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Product not found' }, status: :not_found
      end
    end
  end
end
