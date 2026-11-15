# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Votes', type: :request do
  let!(:hot) { create(:product) }
  let!(:meh) { create(:product) }
  let!(:quiet) { create(:product) }

  before do
    Vote.create!(product: hot, session_id: 'me', value: 1)
    Vote.create!(product: hot, session_id: 'a', value: 1)
    Vote.create!(product: hot, session_id: 'b', value: -1)
    Vote.create!(product: meh, session_id: 'a', value: -1)
  end

  describe 'GET /api/v1/votes' do
    it 'returns the counts and my vote for every deal asked for, in one request' do
      get '/api/v1/votes', params: { deal_ids: "#{hot.id},#{meh.id},#{quiet.id}" },
                           headers: { 'X-Session-Id' => 'me' }

      expect(response).to have_http_status(:ok)
      votes = JSON.parse(response.body)['votes']
      expect(votes[hot.id.to_s]).to eq('upvotes' => 2, 'downvotes' => 1, 'user_vote' => 1)
      expect(votes[meh.id.to_s]).to eq('upvotes' => 0, 'downvotes' => 1, 'user_vote' => nil)
      expect(votes[quiet.id.to_s]).to eq('upvotes' => 0, 'downvotes' => 0, 'user_vote' => nil)
    end

    it 'matches what the single deal endpoint returns' do
      get "/api/v1/deals/#{hot.id}/vote", headers: { 'X-Session-Id' => 'me' }
      single = JSON.parse(response.body)

      get '/api/v1/votes', params: { deal_ids: hot.id.to_s }, headers: { 'X-Session-Id' => 'me' }
      expect(JSON.parse(response.body)['votes'][hot.id.to_s]).to eq(single)
    end

    it 'leaves my vote empty without a session' do
      get '/api/v1/votes', params: { deal_ids: hot.id.to_s }
      expect(JSON.parse(response.body)['votes'][hot.id.to_s]['user_vote']).to be_nil
    end

    it 'ignores ids that are not numbers and caps the batch size' do
      ids = ['abc', '-1', hot.id.to_s, *(1..150).map { |i| (hot.id + 10_000 + i).to_s }]
      get '/api/v1/votes', params: { deal_ids: ids.join(',') }

      votes = JSON.parse(response.body)['votes']
      expect(votes.size).to eq(Api::V1::VotesController::MAX_BATCH)
      expect(votes.keys).to include(hot.id.to_s)
      expect(votes.keys).not_to include('abc', '-1')
    end

    it 'returns nothing when no ids are given' do
      get '/api/v1/votes'
      expect(JSON.parse(response.body)).to eq('votes' => {})
    end
  end
end
