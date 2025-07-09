# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Properties::DetailsCrawler do
  let(:path) { 'new/path/come/here' }
  let(:crawler) { described_class.new(path) }

  describe '#call' do
    before do
      stub_request(:get, %r{\Ahttps://www.property.com.au})
        .to_return(status: 200, body: File.read('spec/fixtures/properties/details/success.html'))

      crawler.call
    end

    it 'fetches property details' do
      expected_data = {
        property_type: "House",
        bedrooms: "-",
        bathrooms: "-",
        car_spaces: "-",
        land_size: "648m²",
        floor_area: "328m²"
      }

      expect(crawler.data).to include(expected_data)
    end
  end
end
