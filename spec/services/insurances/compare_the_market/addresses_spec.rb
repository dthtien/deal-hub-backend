# frozen_string_literal: true
require 'rails_helper'

describe Insurances::CompareTheMarket::Addresses do
  let(:service) { described_class.new(3022, '80 Esmond') }

  describe '#call' do
    before do
      expect(Insurances::CompareTheMarket::RefreshToken)
        .to receive(:new).and_return(
          double(call: double(data: { 'access_token' => 'token' }))
        )
      stub_request(:post, described_class::BASE_URL)
        .to_return(status: 200, body: File.read('spec/fixtures/compare_the_market/addresses.json'))

      service.call
    end

    it do
      expect(service.success?).to be_truthy
      expect(service.data.count).to eq(2)
    end
  end
end

