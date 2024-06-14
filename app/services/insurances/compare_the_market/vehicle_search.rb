# frozen_string_literal: true

module Insurances
  module CompareTheMarket
    class VehicleSearch < ApplicationService
      BASE_URL = 'https://www.comparethemarket.com.au/api/car-journey/lookup/rego'
      STATES_MAP = %w[ACT NSW NT QLD SA TAS VIC WA].freeze
      attr_reader :data, :errors

      def initialize(state, plate, token = ENV['COMPARE_THE_MARKET_TOKEN'])
        @state = state
        @plate = plate
        @errors = []
        @token = token
        @data = nil
      end

      def call
        response = http_client.get(request_url)

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

      attr_reader :state, :plate, :token

      def request_url
        "#{BASE_URL}/#{state}/#{plate}"
      end

      def parse_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        @errors << 'Error while parsing the response'
        {
          data: response.body
        }
      end

      def http_client
        @http_client ||= Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
          faraday.headers['Content-Type'] = 'application/json'
          faraday.headers['Authorization'] = "Bearer #{token}"
          faraday.headers['Accept'] = 'application/json, text/plain, */*'
        end
      end
    end
  end
end
