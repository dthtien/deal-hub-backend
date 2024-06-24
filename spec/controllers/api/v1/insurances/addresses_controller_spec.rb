# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Insurances::AddressesController, type: :controller do
  describe 'GET #index' do
    let(:params) do
      {
        post_code: 3022,
        address_line: '80 Esmond'
      }
    end
    let(:data) do
      JSON.parse(File.read('spec/fixtures/compare_the_market/addresses.json'))
    end

    let(:service) do
      instance_double(
        ::Insurances::CompareTheMarket::Addresses,
        call: nil,
        success?: true,
        data:
      )
    end

    before do
      allow(::Insurances::CompareTheMarket::Addresses).to receive(:new).and_return(service)
      get :index, params:
    end

    it do
      expect(::Insurances::CompareTheMarket::Addresses)
        .to have_received(:new).with(params[:post_code].to_s, params[:address_line])
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(data)
    end
  end
end
