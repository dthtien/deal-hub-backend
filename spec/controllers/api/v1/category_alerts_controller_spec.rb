require 'rails_helper'

RSpec.describe 'Api::V1 Category Alerts', type: :request do
  describe 'POST /api/v1/category_alerts' do
    it 'creates a new category alert' do
      expect {
        post '/api/v1/category_alerts',
          params: { email: 'test@example.com', category: "Women's Fashion" }.to_json,
          headers: { 'Content-Type' => 'application/json' }
      }.to change(CategoryAlert, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns error for missing email' do
      post '/api/v1/category_alerts',
        params: { category: "Women's Fashion" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns error for missing category' do
      post '/api/v1/category_alerts',
        params: { email: 'test@example.com' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'reactivates existing deactivated alert' do
      create(:category_alert, email: 'test@example.com', category: "Women's Fashion", active: false)
      post '/api/v1/category_alerts',
        params: { email: 'test@example.com', category: "Women's Fashion" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:created)
      expect(CategoryAlert.find_by(email: 'test@example.com', category: "Women's Fashion").active).to be true
    end
  end

  describe 'DELETE /api/v1/category_alerts' do
    it 'deactivates an existing alert' do
      create(:category_alert, email: 'test@example.com', category: "Women's Fashion")
      delete '/api/v1/category_alerts',
        params: { email: 'test@example.com', category: "Women's Fashion" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(CategoryAlert.find_by(email: 'test@example.com', category: "Women's Fashion").active).to be false
    end

    it 'returns 404 for non-existent alert' do
      delete '/api/v1/category_alerts',
        params: { email: 'nobody@example.com', category: "Women's Fashion" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:not_found)
    end
  end
end
