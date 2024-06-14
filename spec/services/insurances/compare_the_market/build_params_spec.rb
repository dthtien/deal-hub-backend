# frozen_string_literal: true

describe Insurances::CompareTheMarket::BuildParams do
  describe '#call' do
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
        driver_gender: 'male',
        driver_first_name: 'John',
        driver_last_name: 'Doe',
        driver_email: 'test@gmail.com',
        driver_phone_number: '0412345678',
        driver_employment_status: 'full_time',
        driver_licence_age: 25,
        modified: false,
        has_other_accessories: false,
        has_claim_occurrences: false,
        claim_occurrences: [],
        additional_drivers: [],
        has_younger_driver: false,
        driver_option: 'drivers_21',
        parking: {
          type: 'garage',
          indicator: 'same_suburb'
        },
        km_per_year: 4000
      }
    end

    let(:service) { described_class.new(details, {}) }
    let(:transaction_data) do
      JSON.parse File.read('spec/fixtures/compare_the_market/transaction.json')
    end
    let(:create_transaction_service) do
      double(
        call: double(
          data: transaction_data
        )
      )
    end
    let(:address_check_service) do
      double(
        call: nil,
        data: JSON.parse(File.read('spec/fixtures/suncorp/address.json'))
      )
    end

    let(:vehicle_search_service) do
      double(
        call: double(
          data: JSON.parse(File.read('spec/fixtures/compare_the_market/number_plate.json'))
        )
      )
    end

    before do
      expect(Insurances::CompareTheMarket::CreateTransaction)
        .to receive(:new).and_return(create_transaction_service)
      expect(Insurances::Address::Check)
        .to receive(:new).and_return(address_check_service)
      expect(Insurances::CompareTheMarket::VehicleSearch)
        .to receive(:new).and_return(vehicle_search_service)

      service.call
    end

    it do
      expected_params = JSON.parse File.read('spec/fixtures/compare_the_market/quote_params.json')
      expect(service.params).to be_present
      expect(service.params).to match(expected_params)
    end
  end
end
