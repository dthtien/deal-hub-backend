# frozen_string_literal: true
require 'rails_helper'

describe Insurances::CompareTheMarket::Quote do
  let!(:user) { create(:user) }
  let!(:quote) { create(:quote, user:) }
  let(:service) { described_class.new(quote) }
  let(:params) do
    JSON.parse(File.read('spec/fixtures/compare_the_market/quote_params.json')).with_indifferent_access
  end

  describe '#call' do
    context 'when request successfully' do
      before do
        expect(Insurances::CompareTheMarket::BuildParams)
          .to receive(:new).and_return(double(call: double(params:)))
        expect(Insurances::CompareTheMarket::RefreshToken)
          .to receive(:call).and_return(double(data: {}))
        expect(Insurances::CompareTheMarket::QuoteItems::Store)
          .to receive(:new).and_return(double(call: nil))
        stub_request(:post, described_class::BASE_URL)
          .to_return(status: 200, body: File.read('spec/fixtures/compare_the_market/quote.json'))

        service.call
      end

      it do
        expect(service.success?).to be_truthy
        expect(service.data).to include('quote', 'quoteReceipts')
      end
    end

    context 'when request failed' do
      before do
        expect(Insurances::CompareTheMarket::BuildParams)
          .to receive(:new).and_return(double(call: double(params:)))
        expect(Insurances::CompareTheMarket::RefreshToken)
          .to receive(:call).and_return(double(data: {}))
        stub_request(:post, described_class::BASE_URL)
          .to_return(status: 400, body: { error: 'Bad request' }.to_json)

        service.call
      end

      it do
        quote_item = quote.quote_items.find_by(provider: QuoteItem::COMPARE_THE_MARKET)

        expect(service.success?).to be_falsey
        expect(service.errors).to include('Error while fetching data from the API')
        expect(quote_item.failed?).to be_truthy
      end

    end
  end
end
