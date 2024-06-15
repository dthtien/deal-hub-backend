# frozen_string_literal: true

module Insurances
  module Suncorp
    module QuoteItems
      class Store < ApplicationService
        attr_reader :quote_item

        def initialize(quote, data)
          @quote = quote
          @data = data
          @quote_item = nil
        end

        def call
          @quote_item = quote.quote_items.find_or_initialize_by(provider: QuoteItem::AAMI)
          annual_price = data.dig('quoteDetails', 'premium', 'annualPremium')
          monthly_price = data.dig('quoteDetails', 'premium', 'monthlyPremium')
          cover_type = data.dig('coverDetails', 'coverType')
          description = data['personalisedClaimsQSPMessage']
          quote_item.update!(
            annual_price:,
            monthly_price:,
            cover_type:,
            description:,
            response_details: data
          )

          self
        end

        private

        attr_reader :quote, :data
      end
    end
  end
end
