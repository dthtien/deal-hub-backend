# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::V1::DealsController, :controller, type: :controller do
  describe 'GET #index' do
    let!(:product) { create(:product) }

    before { get :index }
    it 'returns a success response' do
      json_response = JSON.parse(response.body)
      products = json_response['products']
      metadata = json_response['metadata']

      expect(response).to have_http_status(:success)
      expect(products.size).to eq(1)
      expect(products.first['id']).to eq(product.id)
      expect(metadata.with_indifferent_access).to match(
        page: 1,
        per_page: 25,
        total_count: 1,
        total_pages: 1
      )
    end
  end

  describe 'GET #expiring_soon' do
    # products has no expires_at column; the expiry time lives in flash_expires_at
    let!(:ending_first) { create(:product, flash_expires_at: 2.hours.from_now) }
    let!(:ending_later) { create(:product, flash_expires_at: 30.hours.from_now) }
    let!(:ending_next_week) { create(:product, flash_expires_at: 7.days.from_now) }
    let!(:already_ended) { create(:product, flash_expires_at: 1.hour.ago) }
    let!(:no_expiry) { create(:product) }

    it 'returns deals ending within 48 hours, soonest first' do
      get :expiring_soon

      json_response = JSON.parse(response.body)
      expect(response).to have_http_status(:success)
      expect(json_response['products'].map { |p| p['id'] }).to eq([ending_first.id, ending_later.id])
      expect(json_response['metadata']['total_count']).to eq(2)
    end
  end
end
