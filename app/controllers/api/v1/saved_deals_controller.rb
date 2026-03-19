# frozen_string_literal: true

module Api
  module V1
    class SavedDealsController < ApplicationController
      before_action :authenticate_user!

      def index
        products = current_user.saved_products.order('saved_deals.created_at DESC')
        render json: { saved_deals: products.map(&:as_json) }
      end

      def create
        product = Product.find(params[:product_id])
        saved = current_user.saved_deals.find_or_create_by(product_id: product.id)

        if saved.persisted?
          render json: { saved: true, product_id: product.id }, status: :created
        else
          render json: { errors: saved.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Product not found' }, status: :not_found
      end

      def destroy
        saved = current_user.saved_deals.find_by(product_id: params[:id])
        if saved
          saved.destroy
          render json: { saved: false, product_id: params[:id].to_i }
        else
          render json: { error: 'Not found' }, status: :not_found
        end
      end
    end
  end
end
