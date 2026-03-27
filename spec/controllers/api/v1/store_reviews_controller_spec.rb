require 'rails_helper'

RSpec.describe 'Api::V1 Store Reviews', type: :request do
  describe 'GET /api/v1/stores/:store_name/reviews' do
    before do
      create(:store_review, store_name: 'Kmart', rating: 5)
      create(:store_review, store_name: 'Kmart', rating: 3)
    end

    it 'returns reviews and avg_rating' do
      get '/api/v1/stores/Kmart/reviews'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['reviews'].length).to eq(2)
      expect(json['avg_rating']).to eq(4.0)
      expect(json['review_count']).to eq(2)
    end
  end

  describe 'POST /api/v1/stores/:store_name/reviews' do
    it 'creates a review' do
      expect {
        post '/api/v1/stores/Kmart/reviews',
          params: { rating: 5, comment: 'Great!', session_id: 'sess-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
      }.to change(StoreReview, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns error for invalid rating' do
      post '/api/v1/stores/Kmart/reviews',
        params: { rating: 6, session_id: 'sess-123' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns error for missing session_id' do
      post '/api/v1/stores/Kmart/reviews',
        params: { rating: 4 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
