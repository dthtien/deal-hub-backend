# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MetadataController, type: :controller do
  describe 'GET #show' do
    it do
      get :show

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq({ brands: [], categories: [], stores: [] }.to_json)
    end
  end
end
