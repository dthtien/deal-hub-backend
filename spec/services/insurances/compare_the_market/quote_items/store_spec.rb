# frozen_string_literal: true
require 'rails_helper'

describe Insurances::CompareTheMarket::QuoteItems::Store do
  let!(:user) { create(:user) }
  let!(:quote) { create(:quote, user:) }
  let(:service) { described_class.new(quote, data) }
  let(:data) do
    JSON.parse(File.read('spec/fixtures/compare_the_market/quote.json'))
  end

  describe '#call' do
    before do
      service.call
    end

    it do
      quote_items = service.quote_items

      expect(quote_items.count).to eq 10
    end
  end
end
