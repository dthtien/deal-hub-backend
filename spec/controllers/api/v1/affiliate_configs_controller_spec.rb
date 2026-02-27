# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::V1::AffiliateConfigsController, :controller, type: :controller do
  let(:valid_token) { 'test-admin-token' }

  before { allow(ENV).to receive(:fetch).and_call_original }

  describe 'GET #index' do
    let!(:active_config) do
      create(:affiliate_config, store: Product::STORES[0], param_name: 'aff', param_value: '123', active: true)
    end
    let!(:inactive_config) do
      create(:affiliate_config, store: Product::STORES[1], param_name: 'ref', param_value: '456', active: false)
    end

    before { get :index }

    it 'returns a success response' do
      expect(response).to have_http_status(:success)
    end

    it 'returns affiliate_configs map with only active configs' do
      json = JSON.parse(response.body)
      expect(json['affiliate_configs']).to have_key(Product::STORES[0])
      expect(json['affiliate_configs']).not_to have_key(Product::STORES[1])
    end

    it 'returns all configs in the all array' do
      json = JSON.parse(response.body)
      ids = json['all'].map { |c| c['id'] }
      expect(ids).to include(active_config.id, inactive_config.id)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      { affiliate_config: { store: Product::STORES[2], param_name: 'aff', param_value: '789', active: true } }
    end

    context 'with valid admin token' do
      before { allow(ENV).to receive(:fetch).with('ADMIN_API_TOKEN', 'changeme').and_return(valid_token) }

      context 'with valid params' do
        it 'creates a new affiliate config' do
          expect {
            request.headers['X-Admin-Token'] = valid_token
            post :create, params: valid_params
          }.to change(AffiliateConfig, :count).by(1)
        end

        it 'returns created status' do
          request.headers['X-Admin-Token'] = valid_token
          post :create, params: valid_params
          expect(response).to have_http_status(:created)
        end

        it 'returns the created config' do
          request.headers['X-Admin-Token'] = valid_token
          post :create, params: valid_params
          json = JSON.parse(response.body)
          expect(json['affiliate_config']['store']).to eq(Product::STORES[2])
          expect(json['affiliate_config']['param_value']).to eq('789')
        end
      end

      context 'with invalid params' do
        it 'returns unprocessable_entity' do
          request.headers['X-Admin-Token'] = valid_token
          post :create, params: { affiliate_config: { store: '', param_name: '', param_value: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns errors' do
          request.headers['X-Admin-Token'] = valid_token
          post :create, params: { affiliate_config: { store: '', param_name: '', param_value: '' } }
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end
      end
    end

    context 'without admin token' do
      it 'returns unauthorized' do
        post :create, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with wrong admin token' do
      it 'returns unauthorized' do
        request.headers['X-Admin-Token'] = 'wrong-token'
        post :create, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:config) { create(:affiliate_config, store: Product::STORES[0]) }

    context 'with valid admin token' do
      before do
        allow(ENV).to receive(:fetch).with('ADMIN_API_TOKEN', 'changeme').and_return(valid_token)
        request.headers['X-Admin-Token'] = valid_token
      end

      context 'with valid params' do
        it 'updates the config' do
          patch :update, params: { id: config.id, affiliate_config: { param_value: 'new-id' } }
          expect(config.reload.param_value).to eq('new-id')
        end

        it 'returns success' do
          patch :update, params: { id: config.id, affiliate_config: { param_value: 'new-id' } }
          expect(response).to have_http_status(:success)
        end

        it 'returns the updated config' do
          patch :update, params: { id: config.id, affiliate_config: { param_value: 'new-id' } }
          json = JSON.parse(response.body)
          expect(json['affiliate_config']['param_value']).to eq('new-id')
        end
      end

      context 'with invalid params' do
        it 'returns unprocessable_entity' do
          patch :update, params: { id: config.id, affiliate_config: { param_name: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with non-existent id' do
        it 'returns not found' do
          patch :update, params: { id: 99999, affiliate_config: { param_value: 'x' } }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'without admin token' do
      it 'returns unauthorized' do
        patch :update, params: { id: config.id, affiliate_config: { param_value: 'x' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:config) { create(:affiliate_config, store: Product::STORES[0]) }

    context 'with valid admin token' do
      before do
        allow(ENV).to receive(:fetch).with('ADMIN_API_TOKEN', 'changeme').and_return(valid_token)
        request.headers['X-Admin-Token'] = valid_token
      end

      it 'deletes the config' do
        expect {
          delete :destroy, params: { id: config.id }
        }.to change(AffiliateConfig, :count).by(-1)
      end

      it 'returns success' do
        delete :destroy, params: { id: config.id }
        expect(response).to have_http_status(:success)
      end

      context 'with non-existent id' do
        it 'returns not found' do
          delete :destroy, params: { id: 99999 }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'without admin token' do
      it 'returns unauthorized' do
        delete :destroy, params: { id: config.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
