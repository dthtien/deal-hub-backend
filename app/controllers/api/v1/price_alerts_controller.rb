# frozen_string_literal: true

module Api
  module V1
    class PriceAlertsController < ApplicationController
      def create
        alert = PriceAlert.new(price_alert_params)

        if alert.save
          render json: { message: 'Alert created successfully' }, status: :created
        else
          render json: { errors: alert.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def price_alert_params
        params.require(:price_alert).permit(:email, :target_price, :product_id)
      end
    end
  end
end
