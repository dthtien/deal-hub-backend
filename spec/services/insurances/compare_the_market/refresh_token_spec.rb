# frozen_string_literal: true
require 'rails_helper'

describe Insurances::CompareTheMarket::RefreshToken do
  let(:service) { described_class.new }

  describe '#call' do
    before do
      stub_request(:get, described_class::BASE_URL)
        .to_return(status: 200, body: File.read('spec/fixtures/compare_the_market/refresh_token.json'))

      service.call
    end

    it do
      expect(service.success?).to be_truthy
      expect(service.data).to include('access_token', 'refresh_token', 'expires_in', 'token_type')
    end
  end
end

