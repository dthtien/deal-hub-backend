# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MetadataController, type: :controller do
  describe 'GET #show' do
    it do
      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['brands']).to eq([])
      expect(json['categories']).to eq([])
      expect(json['stores']).to eq([])
      expect(json['subscriber_count']).to eq(0)
      expect(json).to have_key('total_count')
      expect(json).to have_key('stores_count')
      expect(json).to have_key('avg_discount')
      expect(json).to have_key('new_today')
      expect(json).to have_key('hot_count')
    end
  end
end
