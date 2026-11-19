# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rate limiting', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  # The test environment uses a null cache, so give Rack::Attack a real one here.
  # Limits are counted per calendar minute, so hold the clock mid-minute: a run
  # of 300 requests that crossed a minute boundary would start a new count.
  around do |example|
    original = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    travel_to(Time.utc(2026, 1, 1, 12, 0, 30)) { example.run }
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

  describe "Google's crawlers" do
    it 'are not held to the general 300 a minute' do
      statuses = (1..320).map { hit('108.177.2.97') } # one of Google's published special-crawler addresses

      expect(statuses).to all(satisfy { |s| s != 429 })
    end

    it 'are recognised from the published ranges only' do
      expect(Rack::Attack.trusted_crawler?('66.249.75.166')).to be true  # Googlebot
      expect(Rack::Attack.trusted_crawler?('108.177.2.99')).to be true   # special crawlers
      expect(Rack::Attack.trusted_crawler?('34.22.220.76')).to be false  # a Google Cloud customer, not Google
      expect(Rack::Attack.trusted_crawler?('203.0.113.9')).to be false
      expect(Rack::Attack.trusted_crawler?('not an address')).to be false
    end
  end

  describe 'price history CSV downloads' do
    def download(ip, deal_id = 1)
      get "/api/v1/deals/#{deal_id}/price_histories.csv", headers: { 'REMOTE_ADDR' => ip }
      response.status
    end

    it 'allows an address 5 a minute and 20 an hour' do
      statuses = (1..6).map { download('203.0.113.20') }
      expect(statuses.first(5)).to all(satisfy { |s| s != 429 })
      expect(statuses.last).to eq(429)
      expect(hit('203.0.113.20')).not_to eq(429) # the rest of the API is unaffected

      # 5 a minute for 4 minutes is 20 in the hour; the 21st is refused
      hourly = (1..4).flat_map do
        travel 1.minute
        (1..5).map { download('203.0.113.21') }
      end
      expect(hourly).to all(satisfy { |s| s != 429 })
      travel 1.minute
      expect(download('203.0.113.21')).to eq(429)
    end

    it 'counts the CSV however it is asked for' do
      ip = '203.0.113.30'
      get '/api/v1/deals/1/price_histories', params: { format: 'csv' }, headers: { 'REMOTE_ADDR' => ip }
      get '/api/v1/deals/1/price_histories', headers: { 'REMOTE_ADDR' => ip, 'HTTP_ACCEPT' => 'text/csv' }
      head '/api/v1/deals/1/price_histories.csv', headers: { 'REMOTE_ADDR' => ip }
      2.times { download(ip) }
      expect(download(ip)).to eq(429)

      # the JSON version is not a download
      6.times { get '/api/v1/deals/1/price_histories', headers: { 'REMOTE_ADDR' => '203.0.113.31' } }
      expect(response.status).not_to eq(429)
    end

    it 'caps downloads from all addresses together at 30 a minute' do
      statuses = (1..31).map { |i| download("198.51.100.#{i}", i) }

      expect(statuses.first(30)).to all(satisfy { |s| s != 429 })
      expect(statuses.last).to eq(429)
      expect(hit('198.51.100.99')).not_to eq(429)
    end
  end

  it 'limits a single ordinary address to 300 requests a minute' do
    statuses = (1..301).map { hit('203.0.113.9') }

    expect(statuses.first(300)).to all(satisfy { |s| s != 429 })
    expect(statuses.last).to eq(429)
  end
end
