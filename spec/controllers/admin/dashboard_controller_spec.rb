require 'rails_helper'

RSpec.describe 'Admin Dashboard', type: :request do
  let(:headers) do
    {
      'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
        ENV.fetch('ADMIN_USERNAME', 'admin'),
        ENV.fetch('ADMIN_PASSWORD', 'changeme')
      )
    }
  end

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
