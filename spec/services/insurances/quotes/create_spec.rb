# frozen_string_literal: true

require 'rails_helper'

describe Insurances::Quotes::Create do
  let(:params) do
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
      driver: {
        date_of_birth: '1990-09-01',
        gender: 'male',
        first_name: 'John',
        last_name: 'Doe',
        email: 'test@gmail',
        phone_number: '0412345678',
        employment_status: 'full_time',
        licence_age: 25
      },
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

  let(:service) { described_class.new(params) }

  describe '#call' do
    before do
      expect(Insurances::QuoteWorkflow)
        .to receive(:create).and_return(double(start!: true))
      service.call
    end

    it do
      user = service.user

      expect(user).to be_persisted
      expect(user.email).to eq('test@gmail')
      expect(user.phone_number).to eq('0412345678')
      expect(user.first_name).to eq('John')
      expect(user.last_name).to eq('Doe')
      expect(user.date_of_birth).to eq(Date.new(1990, 9, 1))
    end

    it do
      quote = service.quote

      expect(quote).to be_persisted
      expect(quote.status).to eq Quote::INITIATED
      expect(quote.policy_start_date).to eq(Date.new(2024, 7, 1))
      expect(quote.current_insurer).to eq('AAMI')
      expect(quote.state).to eq('VIC')
      expect(quote.suburb).to eq('Ardeer')
      expect(quote.postcode).to eq('3022')
      expect(quote.address_line1).to eq('78 Esmond Street')
      expect(quote.plate).to eq('ZZB619')
      expect(quote.financed).to eq(false)
      expect(quote.primary_usage).to eq('private')
      expect(quote.days_wfh).to eq('1_to_2')
      expect(quote.peak_hour_driving).to eq(false)
      expect(quote.cover_type).to eq('comprehensive')
      expect(quote.driver_dob).to eq(Date.new(1990, 9, 1))
      expect(quote.driver_first_name).to eq('John')
      expect(quote.driver_last_name).to eq('Doe')
      expect(quote.driver_email).to eq('test@gmail')
      expect(quote.driver_phone_number).to eq('0412345678')
      expect(quote.driver_employment_status).to eq('full_time')
      expect(quote.driver_licence_age).to eq(25.to_s)
      expect(quote.modified).to eq(false)
      expect(quote.has_claim_occurrences).to eq(false)
      expect(quote.has_other_accessories).to eq(false)
      expect(quote.claim_occurrences).to eq([])
      expect(quote.additional_drivers).to eq([])
      expect(quote.has_younger_driver).to eq(false)
      expect(quote.parking).to eq('type' => 'garage', 'indicator' => 'same_suburb')
      expect(quote.km_per_year).to eq(4000)
    end
  end
end
