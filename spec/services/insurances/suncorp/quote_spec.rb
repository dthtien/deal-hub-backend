# frozen_string_literal: true
require 'rails_helper'

describe Insurances::Suncorp::Quote do
  let!(:user) { create(:user) }
  let!(:quote) { create(:quote, user:) }
  let(:service) { described_class.new(quote) }
  let(:params) do
    JSON.parse(File.read('spec/fixtures/suncorp/quote_params.json')).with_indifferent_access
  end

  describe '#call' do
    before do
      expect(Insurances::Suncorp::BuildParams)
        .to receive(:new).and_return(double(call: nil, params:))
      stub_request(:post, described_class::BASE_URL)
        .to_return(status: 200, body: File.read('spec/fixtures/suncorp/quote.json'))

      service.call
    end

    it do
      expect(service.success?).to be_truthy
      expect(service.data).to include('quoteDetails', 'coverDetails')
    end
  end
end

