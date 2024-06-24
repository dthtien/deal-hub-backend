# frozen_string_literal: true

module Insurances
  module CompareTheMarket
    class Addresses < ApplicationService
      BASE_URL = 'https://www.comparethemarket.com.au/api/address/streetsuburb'

      attr_reader :data, :errors

      def initialize(post_code, address_line)
        @data = nil
        @errors = []
        @post_code = post_code
        @address_line = address_line
      end

      def call
        response = http_client.post(BASE_URL) do |request|
          request.body = params.to_json
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

      attr_reader :post_code, :address_line

      def params
        {
          addressLine: address_line,
          postCodeOrSuburb: post_code
        }
      end

      def token_data
        @token_data ||= RefreshToken.new.call.data
      end

      def http_client
        @http_client ||= Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
          faraday.headers['Content-Type'] = 'application/json'
          faraday.headers['Accept'] = 'application/json, text/plain, */*'
          faraday.headers['Authorization'] = "Bearer #{token_data['access_token']}"
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
