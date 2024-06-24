# frozen_string_literal: true

module Insurances
  module CompareTheMarket
    class RefreshToken < ApplicationService
      BASE_URL = 'https://www.comparethemarket.com.au/api/account/token/anonymous/ctm'

      attr_reader :data, :errors

      def initialize
        @data = nil
        @errors = []
      end

      def call
        response = http_client.get(BASE_URL)

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
