# frozen_string_literal: true

module Properties
  class SuggestionCrawler < ApplicationCrawler
    BASE_URL = 'https://suggest.realestate.com.au/consumer-suggest/suggestions'
    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json, text/plain, */*',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/'
    }.freeze

    attr_reader :data

    def initialize(query)
      super(BASE_URL)
      @query = query
      @data = []
    end

    def call
      @data = suggestions

      self
    end

    private

    attr_reader :query

    def suggestions
      @suggestions ||= begin
        raw = parsed_response&.dig('_embedded', 'suggestions')
        Array(raw).uniq
      end
    end

    def parsed_response
      @parsed_response ||= JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end

    def response
      @response ||= client.get("?#{params.to_param}") do |req|
        DEFAULT_HEADERS.each { |key, value| req.headers[key] = value }
      end
    end

    def params
      {
        max: 6,
        type: 'address,suburb,postcode,state,region',
        src: 'reax-multi-intent-search-modal',
        query: query
      }
    end
  end
end
