# frozen_string_literal: true

module Api
  module V1
    class ExchangeRatesController < ApplicationController
      def index
        render json: {
          base: 'AUD',
          rates: Product::EXCHANGE_RATES,
          symbols: Product::CURRENCY_SYMBOLS
        }
      end
    end
  end
end
