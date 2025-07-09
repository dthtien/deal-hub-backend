# frozen_string_literal: true

module Properties
  class DetailsCrawler < ApplicationCrawler
    BASE_URL = 'https://www.property.com.au'
    COOKIE = ENV.fetch('PROPERTY_COM_COOKIE', '')

    DEFAULT_HEADERS = {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language' => 'en-US,en;q=0.8',
      'Cache-Control' => 'no-cache',
      'Pragma' => 'no-cache',
      'Priority' => 'u=0, i',
      'Sec-CH-UA' => '"Not)A;Brand";v="8", "Chromium";v="138", "Brave";v="138"',
      'Sec-CH-UA-Mobile' => '?0',
      'Sec-CH-UA-Platform' => '"macOS"',
      'Sec-Fetch-Dest' => 'document',
      'Sec-Fetch-Mode' => 'navigate',
      'Sec-Fetch-Site' => 'same-origin',
      'Sec-Fetch-User' => '?1',
      'Sec-GPC' => '1',
      'Upgrade-Insecure-Requests' => '1',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      'Cookie' => COOKIE
    }.freeze
    PROPERTY_DETAILS = [
      PROPERTY_TYPE = 'Property type',
      BEDROOMS = 'Bedrooms',
      BATHROOMS = 'Bathrooms',
      CAR_SPACES = 'Car spaces',
      LAND_SIZE = 'Land size',
      FLOOR_AREA = 'Floor area'
    ].freeze

    attr_reader :data

    def initialize(path)
      super(BASE_URL)
      @path = path
      @data = {}
    end

    def call
      @data = {
        property_type: extract_detail(PROPERTY_TYPE),
        bedrooms: extract_detail(BEDROOMS),
        bathrooms: extract_detail(BATHROOMS),
        car_spaces: extract_detail(CAR_SPACES),
        land_size: extract_detail(LAND_SIZE),
        floor_area: extract_detail(FLOOR_AREA),
        estimated_value:,
        estimated_value_confidence:
      }

      self
    end

    private

    attr_reader :path

    def fetch_data
      client.get(path) do |req|
        DEFAULT_HEADERS.each { |k, v| req.headers[k] = v }
      end
    end

    def document
      @document ||= Nokogiri::HTML(fetch_data.body)
    end

    def extract_detail(title)
      property_information_div.css(%([title="#{title}"] p))&.text&.strip
    end

    def property_information_div
      @property_information_div ||= document.at_css('[title="Property type"]').parent
    end

    def estimated_value
      @estimated_value ||= property_value_div.css('[data-testid="valuation-sub-brick-price-text"]')&.text&.strip
    end

    def estimated_value_confidence
      @estimated_value_confidence ||= property_value_div.css('[data-testid="valuation-sub-brick-confidence"]')&.text&.strip
    end

    def property_value_div
      @property_value_div ||= document.at_xpath("//h3[normalize-space(text())='Property value']/ancestor::section[1]")
    end
  end
end
