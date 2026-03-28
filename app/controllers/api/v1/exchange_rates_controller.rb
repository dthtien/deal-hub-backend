# frozen_string_literal: true

module Api
  module V1
    class ExchangeRatesController < ApplicationController
      def index
        rates = Rails.cache.fetch('exchange_rates_aud', expires_in: 1.hour) do
          {
            base: 'AUD',
            rates: Product::EXCHANGE_RATES,
            symbols: Product::CURRENCY_SYMBOLS
          }
        end

        render json: rates
      end
    end
  end
end
