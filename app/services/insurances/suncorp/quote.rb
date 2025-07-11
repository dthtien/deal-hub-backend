# frozen_string_literal: true

module Insurances
  module Suncorp
    class Quote < ApplicationService
      BASE_URL = 'https://api.suncorp.com.au/motor-insurance-quote/api/v1/insurance/motor/brands/AAMI/quotes'
      attr_reader :data, :errors

      def initialize(quote)
        @quote = quote
        @errors = []
        @data = nil
      end

      def call
        perform_request
        store_quote_item
        self
      end

      def success?
        @errors.empty?
      end

      private

      attr_reader :quote

      def perform_request
        response = http_client.post(BASE_URL) do |request|
          request.body = request_body.to_json
        end

        unless response.success?
          @errors << 'Error while fetching data from the API'
          create_item_error(response)
          return self
        end

        @data = parse_response(response)
      end

      def create_item_error(response)
        quote_item = quote.quote_items.find_or_initialize_by(provider: QuoteItem::AAMI)
        quote_item.update!(
          response_details: response.body,
          description: response.body,
          status: QuoteItem.statuses[:failed]
        )
      end

      def store_quote_item
        return unless success?

        service = QuoteItems::Store.new(quote, data)
        service.call
      end

      def http_client
        @http_client ||= Faraday.new(url: BASE_URL) do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
          faraday.headers['Content-Type'] = 'application/json'
          faraday.headers['Accept'] = 'application/vnd.api+json'
          faraday.headers['Cache-Control'] = 'no-cache'
          faraday.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36'
          faraday.headers['X-Client-ID'] = 'aami-motor-ui'
          faraday.headers['X-Client-Version'] = '1.0'
          faraday.headers['X-Request-ID'] = '800b20f5-05b7-4966-a65a-4155571e68a5'
        end
      end

      def details
        @details ||= quote.attributes
                          .except('id', 'created_at', 'updated_at')
                          .with_indifferent_access
      end

      def parse_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        @errors << 'Error while parsing the response'
        {
          data: response.body
        }
      end

      def request_body
        service = BuildParams.new(details)
        service.call

        service.params
      end
    end
  end
end
