# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Trusted proxies' do
  it 'is off unless TRUSTED_PROXY_NETWORKS is set' do
    expect(TrustedProxies::NETWORKS).to be_empty
    expect(TrustedProxies.include?('104.16.0.1')).to be false
  end

  describe 'with a CDN range trusted' do
    # What the initializer installs when TRUSTED_PROXY_NETWORKS lists the range
    around do |example|
      original = Rack::Request.ip_filter
      cdn = IPAddr.new('104.16.0.0/13')
      Rack::Request.ip_filter = ->(ip) { original.call(ip) || (cdn.include?(IPAddr.new(ip)) rescue false) }
      example.run
    ensure
      Rack::Request.ip_filter = original
    end

    def ip_for(forwarded_for)
      Rack::Request.new('REMOTE_ADDR' => '10.42.0.5', 'HTTP_X_FORWARDED_FOR' => forwarded_for).ip
    end

    it 'uses the visitor address the CDN reports' do
      expect(ip_for('203.0.113.5, 104.16.1.1')).to eq('203.0.113.5')
    end

    it 'does not believe an address that did not come through the CDN' do
      # A direct visitor: the ingress records only who really connected
      expect(ip_for('198.51.100.9')).to eq('198.51.100.9')
      # A forged left-hand entry is ignored: the last untrusted hop wins
      expect(ip_for('1.2.3.4, 198.51.100.9')).to eq('198.51.100.9')
    end
  end

  it 'serves a robots.txt that keeps AI crawlers out and lets search engines in' do
    robots = Rails.public_path.join('robots.txt').read

    expect(robots).to match(/^User-agent: GPTBot$/)
    expect(robots).to match(/^User-agent: Reflectionbot$/)
    expect(robots).to match(/^User-agent: ElevenlabsCrawler$/)
    expect(robots).not_to match(/^User-agent: Googlebot$/)

    everyone = robots.split(/^User-agent: \*$/).last
    expect(everyone).not_to match(%r{^Disallow: /$})
    expect(everyone).not_to match(%r{^Disallow: /api/?$}) # search engines render pages with it
    expect(everyone).to match(%r{^Disallow: /\*\.csv\$$})
  end
end
