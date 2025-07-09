# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::V1::AddressSuggestionsController, type: :controller do
  describe "GET #index" do
    context "when terms are missing" do
      it do
        get :index
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Missing search terms' })
      end
    end

    context "when terms are provided" do
      context "when no suggestions are found" do
        it do
          allow(Properties::Suggest).to receive(:new).and_return(double(call: nil, data: []))
          get :index, params: { terms: 'nonexistent address' }
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)).to eq({ 'error' => 'Not Found' })
        end
      end

      context "when suggestions are found" do
        it do
          data = [
            {
              address: '123 Main St, Springfield, IL',
              id: 1,
              path: 'il/springfield-62701/main-st/123-pid-1/'
            }
          ]
          service = instance_double(Properties::Suggest, data:, call: true)

          allow(Properties::Suggest).to receive(:new).and_return(service)
          get :index, params: { terms: '123 Main St, Springfield, IL' }
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to eq(data.as_json)
        end
      end
    end
  end
end
