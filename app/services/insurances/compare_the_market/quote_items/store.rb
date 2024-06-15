# frozen_string_literal: true

module Insurances
  module CompareTheMarket
    module QuoteItems
      class Store < ApplicationService
        attr_reader :quote_items

        def initialize(quote, data)
          @quote = quote
          @data = data
          @quote_items = quote.quote_items.none
        end

        def call
          quote_results = data.dig('quote', 'payload', 'results', 0, 'quotes')

          return self if quote_results.blank?

          attributes = quote_results.map do |quote_result|
            build_attributes(quote_result)
          end.compact
          return self if attributes.blank?

          @quote_items = quote.quote_items.upsert_all(
            attributes, unique_by: %i[quote_id provider cover_type]
          )

          self
        end

        private

        attr_reader :quote, :data

        def build_attributes(result)
          monthly_price = result.dig('productMeta', 'price', 'monthlyPremium')
          annual_price = result.dig('productMeta', 'price', 'annualPremium')

          return if invalid_result?(monthly_price, annual_price)

          provider = result.dig('providerMeta', 'name')
          cover_type = result.dig('productMeta', 'name')
          description = result.dig('productMeta', 'discount', 'discountOffer')

          {
            quote_id: quote.id,
            provider:,
            monthly_price:,
            annual_price:,
            cover_type:,
            description:,
            response_details: result
          }
        end

        def invalid_result?(monthly_price, annual_price)
          monthly_price.blank? && annual_price.blank? ||
            monthly_price.to_f.zero? && annual_price.to_f.zero?
        end
      end
    end
  end
end
