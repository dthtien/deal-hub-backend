# frozen_string_literal: true

module Api
  module V1
    class DealRatingsController < ApplicationController
      def show
        product = Product.find(params[:deal_id])
        ratings = product.deal_ratings
        average = ratings.average(:rating)&.to_f&.round(1) || 0.0
        count = ratings.count
        session_id = params[:session_id]
        user_rating = session_id.present? ? ratings.find_by(session_id: session_id)&.rating : nil
        render json: { average: average, count: count, user_rating: user_rating }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def create
        product = Product.find(params[:deal_id])
        session_id = params[:session_id].to_s
        rating_value = params[:rating].to_i

        rating = product.deal_ratings.find_or_initialize_by(session_id: session_id)
        rating.rating = rating_value

        if rating.save
          ratings = product.deal_ratings
          render json: {
            average: ratings.average(:rating)&.to_f&.round(1) || 0.0,
            count: ratings.count,
            user_rating: rating_value
          }
        else
          render json: { errors: rating.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end
    end
  end
end
