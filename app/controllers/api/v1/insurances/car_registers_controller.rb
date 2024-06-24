module Api
  module V1
    module Insurances
      class CarRegistersController < ApplicationController
        def index
          token_data = ::Insurances::CompareTheMarket::RefreshToken.new.call.data
          service = ::Insurances::CompareTheMarket::VehicleSearch.new(
            params[:plate_state],
            params[:plate],
            token_data['access_token']
          )
          service.call

          if service.success?
            render json: service.data, status: :ok
          else
            render json: { errors: service.errors }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
