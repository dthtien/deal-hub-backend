# frozen_string_literal: true
#
module Insurances
  module Suncorp
    class Quote < ApplicationService
      BASE_URL = 'https://api.suncorp.com.au/motor-insurance-quote/api/v1/insurance/motor/brands/AAMI/quotes'

      def initialize(details)
        @details = details
      end

      def call
        http_client.post(BASE_URL) do |request|
          request.body = request_body.to_json
        end
      end

      private

      attr_reader :details

      def http_client
        @http_client ||= Faraday.new(url: BASE_URL) do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
          faraday.headers['Content-Type'] = 'application/json'
          faraday.headers['Accept'] = 'application/vnd.api+json'
          faraday.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome'
          faraday.headers['X-Client-ID'] = 'aami-motor-ui'
          faraday.headers['X-Client-Version'] = '1.0'
          faraday.headers['X-Request-ID'] = 'd94af332-f212-4b54-8a7c-b899e08d70ac'
        end
      end

      def request_body
        service = BuildParams.new(details)
        service.call

        service.params
      end
    end
  end
end
