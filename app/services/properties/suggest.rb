# frozen_string_literal: true

module Properties
  class Suggest < ApplicationService
    attr_reader :data

    def initialize(address)
      @address = address
      @data = nil
    end

    def call
      @data = suggestions

      self
    end

    private

    attr_reader :address

    def crawler
      @crawler ||= SuggestionCrawler.new(address)
    end

    def suggestions
      @suggestions ||=
        begin
          crawler.call
          build_suggestions
        end
    end

    def build_suggestions
      crawler.data.map do |suggestion|
        {
          address: suggestion.dig('display', 'text'),
          path: build_path(suggestion),
          id: suggestion['id']
        }
      end
    end

    def build_path(suggestion)
      source = suggestion['source']
      id = suggestion['id']

      state = source['state'].downcase
      suburb = source['suburb'].downcase
      postcode = source['postcode']
      street = source['streetName'].downcase.parameterize
      street_number = source['streetNumber']

      "#{state}/#{suburb}-#{postcode}/#{street}/#{street_number}-pid-#{id}/"
    end
  end
end
