module Api
  module V1
    module Insurances
      class AddressesController < ApplicationController
        def index
          service = ::Insurances::CompareTheMarket::Addresses.new(params[:post_code], params[:address_line])
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
