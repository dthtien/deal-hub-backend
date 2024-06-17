module Api
  module V1
    module Insurances
      class QuotesController < ApplicationController
        def create
          service = ::Insurances::Quotes::Create.new(quote_params.to_h)
          service.call

          if service.success?
            render json: service.quote, status: :created
          else
            render json: { errors: service.errors }, status: :unprocessable_entity
          end
        end

        def show
          render json: Quote.find(params[:id])
        end

        private

        def quote_params
          params
            .require(:quote)
            .permit(
              :policy_start_date,
              :current_insurer,
              :state,
              :suburb,
              :postcode,
              :address_line1,
              :plate,
              :financed,
              :primary_usage,
              :days_wfh,
              :peak_hour_driving,
              :cover_type,
              :modified,
              :driver_option,
              :km_per_year,
              driver: %i[date_of_birth first_name last_name gender email phone_number employment_status licence_age],
              parking: %i[indicator type]
            )
        end
      end
    end
  end
end
