# frozen_string_literal: true

module Api
  module V1
    class PriceAlertsController < ApplicationController
      def create
        product = Product.find(params[:product_id])
        alert = product.price_alerts.new(alert_params)

        if alert.save
          render json: { message: 'Alert set! We will email you when price drops.' }, status: :created
        else
          render json: { errors: alert.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def alert_params
        params.require(:price_alert).permit(:email, :target_price)
      end
    end
  end
end
