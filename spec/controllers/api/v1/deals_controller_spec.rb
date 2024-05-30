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
        show_next_page: false
      )
    end
  end
end
