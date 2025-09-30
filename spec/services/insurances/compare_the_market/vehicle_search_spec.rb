# frozen_string_literal: true
require 'rails_helper'

describe Insurances::CompareTheMarket::VehicleSearch do
  let(:state) { 'NSW' }
  let(:plate) { 'ABC123' }
  let(:service) { described_class.new(state, plate) }

  describe '#call' do
    before do
      stub_request(:get, "https://www.comparethemarket.com.au/api/car-journey/lookup/rego/#{state}/#{plate}?brand_code=ctm")
        .to_return(status: 200, body: File.read('spec/fixtures/compare_the_market/number_plate.json'))

      service.call
    end

    it do
      expect(service.success?).to be_truthy
      expect(service.data).to include('make', 'colour', 'model')
    end
  end
end
