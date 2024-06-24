# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Insurances::QuotesController, type: :controller do
  describe 'POST #create' do
    let(:params) do
      {
        quote: {
          policy_start_date: '2024-07-01',
          current_insurer: 'AAMI',
          state: 'VIC',
          suburb: 'Ardeer',
          postcode: '3022',
          address_line1: '78 Esmond Street',
          plate: 'ZZB619',
          financed: false,
          primary_usage: 'private',
          days_wfh: '1_to_2',
          peak_hour_driving: false,
          cover_type: 'comprehensive',
          driver: {
            date_of_birth: '1990-09-01',
            gender: 'male',
            first_name: 'John',
            last_name: 'Doe',
            email: 'test@gmail',
            phone_number: '0412345678',
            employment_status: 'full_time',
            licence_age: 25
          },
          modified: false,
          driver_option: 'drivers_21',
          parking: {
            type: 'garage',
            indicator: 'same_suburb'
          },
          km_per_year: 4000
        }
      }
    end

    context 'when successful' do
      let(:quote_service) do
        instance_double(
          Insurances::Quotes::Create,
          call: true,
          quote: build(:quote),
          success?: true
        )
      end
      before do
        expect(Insurances::Quotes::Create)
          .to receive(:new).and_return(quote_service)
        post :create, params:
      end

      it do
        expect(response).to have_http_status(:created)
        expect(response.body).to eq(quote_service.quote.to_json)
      end
    end

    context 'when successful' do
      let(:quote_service) do
        instance_double(
          Insurances::Quotes::Create,
          call: true,
          success?: false,
          errors: ['error']
        )
      end
      before do
        expect(Insurances::Quotes::Create)
          .to receive(:new).and_return(quote_service)
        post :create, params:
      end

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq({ errors: ['error'] }.to_json)
      end
    end
  end

  describe 'GET #show' do
    let(:quote) { create(:quote) }
    let(:quote_service) do
      instance_double(
        Insurances::Quotes::Show,
        call: true,
        quote: ,
        success?: true
      )
    end

    before do
      get :show, params: { id: quote.id }
    end

    it do
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(quote.to_json)
    end
  end
end
