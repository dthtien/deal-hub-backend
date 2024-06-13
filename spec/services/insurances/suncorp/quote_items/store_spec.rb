# frozen_string_literal: true
require 'rails_helper'

describe Insurances::Suncorp::QuoteItems::Store do
  let!(:user) { create(:user) }
  let!(:quote) { create(:quote, user:) }
  let(:service) { described_class.new(quote, data) }
  let(:data) do
    JSON.parse(File.read('spec/fixtures/suncorp/quote.json')).with_indifferent_access
  end

  describe '#call' do
    before do
      service.call
    end

    it do
      quote_item = service.quote_item

      expect(quote_item).to be_persisted
      expect(quote_item.response_details).to eq(data)
      expect(quote_item.quote).to eq(quote)
      expect(quote_item.annual_price).to eq(data[:quoteDetails][:premium][:annualPremium])
      expect(quote_item.monthly_price).to eq(data[:quoteDetails][:premium][:monthlyPremium])
    end
  end
end
