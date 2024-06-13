# frozen_string_literal: true

module Insurances
  module Address
    class Check < ApplicationService
      BASE_URL = 'https://api.suncorp.com.au/address-search-service/address/find/v3'

      attr_reader :data, :errors

      def initialize(suburb, postcode, state, address_line1)
        @suburb = suburb
        @postcode = postcode
        @state = state
        @address_line1 = address_line1
        @errors = []
        @data = nil
      end

      def call
        response = http_client.post(BASE_URL) do |request|
          request.body = request_body.to_json
        end

        unless response.success?
          @errors << 'Error while fetching data from the API'
          return self
        end

        @data = parse_response(response)
        self
      end

      def success?
        @errors.empty?
      end

      private

      attr_reader :suburb, :postcode, :state, :address_line1

      def request_body
        {
          address: {
            country: 'AUS',
            suburb:,
            postcode:,
            state:,
            addressInFreeForm: {
              addressLine1: address_line1,
            }
          },
          expectedQualityLevels: %w[1 2 3 4 5 6],
          addressSuggestionRequirements: {
            required: true,
            forAddressQualityLevels: %w[3 4 5],
            howMany: '10'
          }
        }
      end

      def http_client
        @http_client ||= Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
          faraday.headers['Content-Type'] = 'application/json'
          faraday.headers['Accept'] = 'application/json, text/plain, */*'
          faraday.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome'
        end
      end

      def parse_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        @errors << 'Error while parsing the response'
        {
          data: response.body
        }
      end
    end
  end
end
