# frozen_string_literal: true

module Insurances
  module CompareTheMarket
    class Quote < Suncorp::Quote
      BASE_URL = 'https://www.comparethemarket.com.au/api/car-journey/journey/result'

      def call
        perform_request
        store_quote_item

        self
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

        self
      end

      def create_item_error(response)
        quote_item = quote.quote_items.find_or_initialize_by(provider: QuoteItem::COMPARE_THE_MARKET)
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
        @http_client ||= Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
          faraday.headers['Content-Type'] = 'application/json'
          faraday.headers['Authorization'] = "Bearer #{token_data['access_token']}"
          faraday.headers['Accept'] = 'application/json, text/plain, */*'
        end
      end

      def token_data
        @token_data ||= RefreshToken.call.data
      end

      def request_body
        BuildParams.new(details, token_data).call.params
      end
    end
  end
end

