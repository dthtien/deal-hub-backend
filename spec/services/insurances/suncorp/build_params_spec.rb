# frozen_string_literal: true
require 'rails_helper'

describe Insurances::Suncorp::BuildParams do
  let(:details) do
    {
      policy_start_date: '2024-07-01',
      current_insurer: 'AAMI',
      state: 'VIC',
      suburb: 'Ardeer',
      postcode: '3022',
      address_line1: '78 Esmond Street',
      plate: 'ZZB619',
      financed: false,
      primary_usage: 'private',
      days_wfh: '1_to_2',
      peak_hour_driving: false,
      cover_type: 'comprehensive',
      driver_dob: '1990-09-01',
      driver_gender: 'Male',
      has_claim_occurrences: false,
      claim_occurrences: [],
      additional_drivers: [],
      parking: {
        indicator: 'same_suburb'
      },
      km_per_year: 4000
    }
  end

  let(:service) { described_class.new(details) }

  describe '#call' do
    before do
      stub_request(:post, Insurances::Address::Check::BASE_URL)
        .to_return(status: 200, body: File.read('spec/fixtures/suncorp/address.json'))
      stub_request(:get, %r{\A#{Insurances::Suncorp::VehicleSearch::BASE_URL}/#{details[:plate]}/details})
        .to_return(status: 200, body: File.read('spec/fixtures/suncorp/vehicle.json'))

      expect(Insurances::Address::Check)
        .to receive(:new)
        .with(details[:suburb], details[:postcode], details[:state], details[:address_line1])
        .and_call_original
      expect(Insurances::Suncorp::VehicleSearch)
        .to receive(:new)
        .with(details[:state], details[:plate], details[:policy_start_date])
        .and_call_original

      service.call
    end

    it do
      params = service.params.with_indifferent_access
      expected_params = JSON.parse File.read('spec/fixtures/suncorp/quote_params.json')

      expect(params).to be_present
      expect(params).to match(expected_params)
    end
  end
end
