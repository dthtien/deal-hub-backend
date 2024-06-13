# frozen_string_literal: true

module Insurances
  module Suncorp
    class VehicleSearch < ApplicationService
      BASE_URL = 'https://api.suncorp.com.au/vehicle-search-service/vehicle/rego'
      attr_reader :data, :errors

      def initialize(state, plate, policy_start_date = Time.current.strftime('%Y-%m-%d'))
        @state = state
        @plate = plate
        @policy_start_date = policy_start_date
        @errors = []
        @data = nil
      end

      def call
        response = http_client.get(request_url, params)

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

      attr_reader :state, :plate, :policy_start_date

      def request_url
        "#{BASE_URL}/#{plate}/details"
      end

      def params
        {
          state:,
          country: 'AUS',
          brand: 'AAMI',
          channel: 'WEB',
          product: 'CAR',
          entryDate: policy_start_date
        }
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
          faraday.headers['Accept'] = '*/*'
          faraday.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/'
          faraday.headers['X-Suncorp-Vehicle-Authorization'] = '2c599f24-43b1-4e75-8c50-597927f7c0c0'
        end
      end
    end
  end
end

