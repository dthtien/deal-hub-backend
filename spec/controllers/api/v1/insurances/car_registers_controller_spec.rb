# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Insurances::CarRegistersController, type: :controller do
  describe 'GET #index' do
    let(:params) do
      {
        plate_state: 'VIC',
        plate: 'abcxyz'
      }
    end
    let(:data) do
      JSON.parse(File.read('spec/fixtures/compare_the_market/number_plate.json'))
    end

    let(:service) do
      instance_double(
        ::Insurances::CompareTheMarket::VehicleSearch,
        call: nil,
        success?: true,
        data:
      )
    end
    let(:token_service) do
      instance_double(
        ::Insurances::CompareTheMarket::RefreshToken,
        call: double(data: { 'access_token' => 'token' })
      )
    end

    before do
      allow(::Insurances::CompareTheMarket::VehicleSearch).to receive(:new).and_return(service)
      allow(::Insurances::CompareTheMarket::RefreshToken).to receive(:new).and_return(token_service)
      get :index, params:
    end

    it do
      expect(::Insurances::CompareTheMarket::VehicleSearch)
        .to have_received(:new).with(params[:plate_state].to_s, params[:plate], 'token')
      expect(::Insurances::CompareTheMarket::RefreshToken).to have_received(:new)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(data)
    end
  end
end
