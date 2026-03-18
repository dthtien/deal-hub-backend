# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DealsController, :controller, type: :controller do
  describe 'GET #redirect' do
    let!(:product) { create(:product, store: 'asos', store_path: 'https://www.asos.com/product/123') }

    before do
      allow(ENV).to receive(:fetch).with('AWIN_ASOS_MID', anything).and_return('12345')
      allow(ENV).to receive(:fetch).with('AWIN_AFFID', anything).and_return('67890')
    end

    context 'with a valid product' do
      before { get :redirect, params: { id: product.id } }

      it 'returns a success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns an affiliate URL' do
        json = JSON.parse(response.body)
        expect(json['affiliate_url']).to include('awin1.com')
      end

      it 'returns click count' do
        json = JSON.parse(response.body)
        expect(json['click_count']).to eq(1)
      end

      it 'creates a click tracking record' do
        expect(ClickTracking.count).to eq(1)
        expect(ClickTracking.last.product_id).to eq(product.id)
        expect(ClickTracking.last.store).to eq('asos')
      end
    end

    context 'with multiple clicks on same product' do
      before do
        2.times { get :redirect, params: { id: product.id } }
      end

      it 'tracks each click separately' do
        expect(ClickTracking.count).to eq(2)
      end

      it 'returns correct click count' do
        json = JSON.parse(response.body)
        expect(json['click_count']).to eq(2)
      end
    end

    context 'with an invalid product id' do
      before { get :redirect, params: { id: 99999 } }

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'does not create a click tracking record' do
        expect(ClickTracking.count).to eq(0)
      end
    end
  end
end
