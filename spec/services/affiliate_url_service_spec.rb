# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AffiliateUrlService do
  subject(:service) { described_class.call(product) }

  describe '#call' do
    context 'with ASOS product' do
      let(:product) { build(:product, store: Product::ASOS, store_path: 'prd/product-name/123456') }

      before do
        allow(ENV).to receive(:fetch).with('AWIN_ASOS_MID', anything).and_return('12345')
        allow(ENV).to receive(:fetch).with('AWIN_AFFID', anything).and_return('67890')
      end

      it 'builds an Awin affiliate URL' do
        expect(service).to include('awin1.com')
        expect(service).to include('awinmid=12345')
        expect(service).to include('awinaffid=67890')
        expect(service).to include('asos.com')
      end
    end

    context 'with Culture Kings product' do
      let(:product) { build(:product, store: Product::CULTURE_KINGS, store_path: 'some-product-slug') }

      before do
        allow(ENV).to receive(:fetch).with('CF_AID', anything).and_return('CF_AID_123')
        allow(ENV).to receive(:fetch).with('CF_CULTURE_KINGS_MID', anything).and_return('CK_MID_456')
      end

      it 'builds a Commission Factory affiliate URL' do
        expect(service).to include('cfjump.com')
        expect(service).to include('CF_AID_123')
        expect(service).to include('CK_MID_456')
        expect(service).to include('culturekings')
      end
    end

    context 'with unknown/unsupported store (The Good Guys)' do
      let(:product) { build(:product, store: Product::THE_GOOD_GUYS, store_path: 'https://www.thegoodguys.com.au/product/789') }

      it 'returns the original store_url unchanged' do
        expect(service).to eq(product.store_url)
      end
    end

    context 'with blank store_path' do
      let(:product) { build(:product, store: Product::ASOS, store_path: nil) }

      it 'returns nil' do
        expect(service).to be_nil
      end
    end
  end
end
