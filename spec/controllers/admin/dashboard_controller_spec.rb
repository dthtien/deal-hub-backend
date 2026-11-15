require 'rails_helper'
require_relative '../../support/admin_credentials'

RSpec.describe 'Admin Dashboard', type: :request do
  let(:headers) { admin_auth_header('admin', 'test-password') }

  around { |example| with_admin_credentials('admin', 'test-password') { example.run } }

  describe 'POST /admin/dashboard/quick_action' do
    it 'queues the crawl distribution job' do
      expect {
        post '/admin/dashboard/quick_action', params: { action_name: 'run_crawl' }, headers: headers
      }.to change { Crawlers::DistributeJob.jobs.size }.by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Crawl job queued.')
    end

    it 'queues the watchlist digest job' do
      expect {
        post '/admin/dashboard/quick_action', params: { action_name: 'send_digest' }, headers: headers
      }.to change { WatchlistDigestJob.jobs.size }.by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Digest job queued.')
    end
  end
end
