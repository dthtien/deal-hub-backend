# frozen_string_literal: true
require 'rails_helper'

describe Insurances::Address::Check do
  let(:state) { 'NSW' }
  let(:suburb) { 'Sydney' }
  let(:postcode) { '2000' }
  let(:address_line1) { '1 Market Street' }
  let(:service) { described_class.new(suburb, postcode, state, address_line1) }

  describe '#call' do
    before do
      stub_request(:post, described_class::BASE_URL)
        .to_return(status: 200, body: File.read('spec/fixtures/suncorp/address.json'))
      service.call
    end

    it do
      expect(service.success?).to be_truthy
      expect(service.data).to include('matchedAddress',)
    end
  end
end

