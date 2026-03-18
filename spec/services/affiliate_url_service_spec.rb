# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AffiliateUrlService do
  subject(:service) { described_class.call(product) }

  describe '#call' do
    context 'with ASOS product' do
      let(:product) { build(:product, store: 'asos', store_path: 'https://www.asos.com/product/123') }

      before do
        allow(ENV).to receive(:fetch).with('AWIN_ASOS_MID', anything).and_return('12345')
        allow(ENV).to receive(:fetch).with('AWIN_AFFID', anything).and_return('67890')
      end

      it 'builds an Awin affiliate URL' do
        expect(service).to include('awin1.com')
        expect(service).to include('awinmid=12345')
        expect(service).to include('awinaffid=67890')
        expect(service).to include(CGI.escape('https://www.asos.com/product/123'))
      end
    end

    context 'with Culture Kings product' do
      let(:product) { build(:product, store: 'culture_kings', store_path: 'https://www.culturekings.com.au/product/123') }

      before do
        allow(ENV).to receive(:fetch).with('CF_AID', anything).and_return('CF_AID_123')
        allow(ENV).to receive(:fetch).with('CF_CULTURE_KINGS_MID', anything).and_return('CK_MID_456')
      end

      it 'builds a Commission Factory affiliate URL' do
        expect(service).to include('cfjump.com')
        expect(service).to include('CF_AID_123')
        expect(service).to include('CK_MID_456')
      end
    end

    context 'with Foot Locker product' do
      let(:product) { build(:product, store: 'foot_locker', store_path: 'https://www.footlocker.com.au/product/456') }

      before do
        allow(ENV).to receive(:fetch).with('CF_AID', anything).and_return('CF_AID_123')
        allow(ENV).to receive(:fetch).with('CF_FOOT_LOCKER_MID', anything).and_return('FL_MID_789')
      end

      it 'builds a Commission Factory affiliate URL' do
        expect(service).to include('cfjump.com')
        expect(service).to include('FL_MID_789')
      end
    end

    context 'with unknown store' do
      let(:product) { build(:product, store: 'unknown_store', store_path: 'https://www.unknown.com/product/789') }

      it 'returns the original store_path' do
        expect(service).to eq('https://www.unknown.com/product/789')
      end
    end

    context 'with blank store_path' do
      let(:product) { build(:product, store: 'asos', store_path: nil) }

      it 'returns nil' do
        expect(service).to be_nil
      end
    end
  end
end
