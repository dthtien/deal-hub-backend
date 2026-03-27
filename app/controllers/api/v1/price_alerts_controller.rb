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

      def destroy
        alert = PriceAlert.find(params[:id])
        alert.destroy
        render json: { ok: true }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def bulk
        alerts_params = Array(params[:alerts]).first(10)

        if alerts_params.empty?
          return render json: { error: 'No alerts provided' }, status: :unprocessable_entity
        end

        results = alerts_params.map do |a|
          product = Product.find_by(id: a[:product_id])
          unless product
            next { success: false, product_id: a[:product_id], error: 'Product not found' }
          end

          alert = product.price_alerts.new(
            target_price: a[:target_price],
            email: a[:email]
          )

          if alert.save
            { success: true, product_id: product.id, alert_id: alert.id, email: alert.email }
          else
            { success: false, product_id: a[:product_id], error: alert.errors.full_messages.join(', ') }
          end
        end.compact

        render json: { results: results }, status: :created
      end

      private

      def alert_params
        params.require(:price_alert).permit(:email, :target_price)
      end
    end
  end
end
