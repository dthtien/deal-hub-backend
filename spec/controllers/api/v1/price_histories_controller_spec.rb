# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::PriceHistoriesController, type: :controller do
  describe 'GET #index' do
    let!(:product) { create(:product) }

    before do
      product.price_histories.create!(price: 9.5, old_price: 12.0, discount: 20.8, recorded_at: Time.current)
    end

    it 'returns JSON when no format is requested' do
      get :index, params: { deal_id: product.id }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      json = JSON.parse(response.body)
      expect(json['price_histories'].size).to eq(1)
    end

    it 'returns JSON for a browser-like Accept header' do
      request.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      get :index, params: { deal_id: product.id }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)).to have_key('price_histories')
    end

    it 'returns JSON when JSON is requested' do
      get :index, params: { deal_id: product.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)['price_histories'].size).to eq(1)
    end

    it 'still returns CSV when CSV is requested' do
      get :index, params: { deal_id: product.id, format: :csv }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.body).to start_with('date,price,old_price,recorded_at')
    end
  end
end
