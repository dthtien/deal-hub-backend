# frozen_string_literal: true
require 'rails_helper'

describe Insurances::Suncorp::VehicleSearch do
  let(:state) { 'NSW' }
  let(:plate) { 'ABC123' }
  let(:service) { described_class.new(state, plate) }

  describe '#call' do
    before do
      stub_request(:get, %r{\A#{described_class::BASE_URL}/#{plate}/details})
        .to_return(status: 200, body: File.read('spec/fixtures/suncorp/vehicle.json'))

      service.call
    end

    it do
      expect(service.success?).to be_truthy
      expect(service.data).to include('vehicleDetails', 'vehicleValueInfo')
    end
  end
end

