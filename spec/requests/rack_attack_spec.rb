# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rate limiting', type: :request do
  # The test environment uses a null cache, so give Rack::Attack a real one here.
  around do |example|
    original = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store = original
  end

  def hit(ip)
    get '/api/v1/exchange_rates', headers: { 'REMOTE_ADDR' => ip }
    response.status
  end

  describe 'networks that send crawler swarms' do
    it 'limits each address in the network to 10 requests a minute' do
      statuses = (1..12).map { hit('43.173.1.1') }

      expect(statuses.first(10)).to all(satisfy { |s| s != 429 })
      expect(statuses.last(2)).to eq([429, 429])
      expect(hit('43.173.1.2')).not_to eq(429) # a neighbour has its own allowance
    end

    it 'cuts a swarm off at the shared ceiling of 300 a minute for the network' do
      # 301 different addresses, one request each: nobody exceeds the per-address limit
      statuses = (0..300).map { |i| hit("43.173.#{i / 250}.#{(i % 250) + 1}") }

      expect(statuses.first(300)).to all(satisfy { |s| s != 429 })
      expect(statuses.last).to eq(429)
      expect(hit('161.120.180.5')).not_to eq(429) # the other network is counted separately
    end

    it 'does not touch addresses outside the listed networks' do
      12.times { hit('43.173.0.9') }

      expect(hit('203.0.113.7')).not_to eq(429)
      expect(Rack::Attack.throttled_network('203.0.113.7')).to be_nil
      expect(Rack::Attack.throttled_network('43.160.0.1')).to eq('43.160.0.0/12')
      expect(Rack::Attack.throttled_network('not an address')).to be_nil
    end
  end

  it 'still limits a single ordinary address to 60 requests a minute' do
    statuses = (1..61).map { hit('203.0.113.9') }

    expect(statuses.first(60)).to all(satisfy { |s| s != 429 })
    expect(statuses.last).to eq(429)
  end
end
