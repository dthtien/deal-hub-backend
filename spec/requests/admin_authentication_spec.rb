# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/admin_credentials'

RSpec.describe 'Admin login', type: :request do
  # One page from the admin area and one from each admin API controller
  paths = ['/admin', '/api/v1/admin/crawler_health', '/api/v1/admin/store_stats']

  paths.each do |path|
    describe "GET #{path}" do
      it 'refuses a request without a login' do
        with_admin_credentials('admin', 'right-password') { get path }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'refuses a wrong password' do
        with_admin_credentials('admin', 'right-password') do
          get path, headers: admin_auth_header('admin', 'wrong-password')
        end
        expect(response).to have_http_status(:unauthorized)
      end

      it 'refuses a wrong username' do
        with_admin_credentials('admin', 'right-password') do
          get path, headers: admin_auth_header('someone', 'right-password')
        end
        expect(response).to have_http_status(:unauthorized)
      end

      it 'accepts the configured login' do
        with_admin_credentials('admin', 'right-password') do
          get path, headers: admin_auth_header('admin', 'right-password')
        end
        expect(response).to have_http_status(:ok)
      end

      it 'refuses the old default login when no login is configured' do
        with_admin_credentials(nil, nil) do
          get path, headers: admin_auth_header('admin', 'changeme')
        end
        expect(response).to have_http_status(:unauthorized)
      end

      it 'refuses an empty login when the configured values are empty' do
        with_admin_credentials('', '') do
          get path, headers: admin_auth_header('', '')
        end
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
