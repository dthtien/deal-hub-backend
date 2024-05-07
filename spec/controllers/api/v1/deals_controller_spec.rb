# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::V1::DealsController, :controller, type: :controller do
  describe 'GET #index' do
    let!(:product) { create(:product) }

    before { get :index }
    it 'returns a success response' do
      json_response = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(product.id)
    end
  end
end
