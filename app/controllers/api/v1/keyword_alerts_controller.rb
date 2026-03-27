# frozen_string_literal: true

module Api
  module V1
    class KeywordAlertsController < ApplicationController
      def create
        alert = PriceAlert.new(
          email: params[:email],
          keyword: params[:keyword]
        )

        if alert.save
          render json: { message: "Alert set! We'll email you when a deal matching \"#{params[:keyword]}\" is found." }, status: :created
        else
          render json: { errors: alert.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
