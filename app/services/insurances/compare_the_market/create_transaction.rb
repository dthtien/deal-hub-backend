# frozen_string_literal: true

module Insurances
  module CompareTheMarket
    class CreateTransaction < ApplicationService
      BASE_URL = 'https://www.comparethemarket.com.au/api/car-journey/journey/new/ctm'

      attr_reader :data, :errors

      def initialize(token_data)
        @data = nil
        @errors = []
        @token_data = token_data
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

      attr_reader :token_data

      def params
        {
          "marketing": {
            "experimentId": nil
          },
          "clientMetadata": {
            "client": {
              "clientDeviceCategory": 'DESKTOP',
              "clientDeviceOS": 'macOS',
              "clientDeviceOSVersion": '',
              "clientBrowser": 'Chromium',
              "clientBrowserVersion": '124',
              "anonymousId": token_data['jti'],
              "userId": ''
            },
            "clientSessionScope": {
              "sessionId": SecureRandom.uuid,
              "referrer": 'www.google.com',
              "utm_medium": nil,
              "utm_source": nil,
              "utm_campaign": nil,
              "utm_content": nil,
              "utm_term": nil,
              "clickID_type": nil,
              "clickID_value": nil,
              "mktCloud_subscriberId": '',
              "reportingChannel": 'Direct'
            }
          },
          "prefill": {
            "lastViewedPage": '/car-insurance/journey/start',
            "eligiblePage": false
          }
        }
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
