require 'ipaddr'

class Rack::Attack
  # Count in Redis when it is available, so every web process and every web
  # pod shares the same counters. Without this each pod keeps its own count
  # and the real limits are multiplied by the number of pods.
  if ENV['REDIS_URL'].present?
    self.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'], namespace: 'rack-attack')
  end

  # Networks that have sent swarms of crawler traffic: thousands of addresses,
  # each making only a few requests. Two kinds of limit apply to them.
  # Override the list with THROTTLED_NETWORKS, a comma separated list of CIDR
  # ranges (set it to an empty string to switch both off).
  #   43.160.0.0/12 and 161.120.176.0/20: Tencent Cloud (Aceville Pte Ltd)
  THROTTLED_NETWORKS = ENV.fetch('THROTTLED_NETWORKS', '43.160.0.0/12,161.120.176.0/20')
                          .split(',').map(&:strip).reject(&:empty?)
                          .to_h { |cidr| [cidr, IPAddr.new(cidr)] }.freeze

  # 1. Per address: tighter than the general limit, because we cannot tell a
  #    real visitor on these networks from a crawler. All three apply at once.
  NETWORK_ADDRESS_LIMITS = [[10, 1.minute], [100, 20.minutes], [200, 1.hour]].freeze

  # 2. Per network: a ceiling shared by every address in the network. Ordinary
  #    traffic from these networks is well under 20 requests a minute, while a
  #    swarm sends 1,400 to 3,700, with no single address exceeding limit 1.
  NETWORK_CEILING_PER_MINUTE = Integer(ENV.fetch('THROTTLED_NETWORK_CEILING', 300))

  def self.throttled_network(ip)
    address = IPAddr.new(ip.to_s)
    THROTTLED_NETWORKS.each { |cidr, range| return cidr if range.include?(address) }
    nil
  rescue IPAddr::Error
    nil
  end

  NETWORK_ADDRESS_LIMITS.each do |limit, period|
    throttle("network-address/#{period.to_i}s", limit: limit, period: period) do |req|
      req.ip if req.path.start_with?('/api/') && throttled_network(req.ip)
    end
  end

  throttle('network-ceiling/60s', limit: NETWORK_CEILING_PER_MINUTE, period: 1.minute) do |req|
    throttled_network(req.ip) if req.path.start_with?('/api/')
  end

  # Google's own crawlers and fetchers, from the address lists Google publishes
  # (config/google_crawler_networks.yml). They render our pages for search, so
  # one of their addresses makes many API calls a minute on behalf of many pages.
  # They are exempt from the general limit below and get a much higher one.
  # TRUSTED_CRAWLER_NETWORKS adds more ranges (comma separated CIDR).
  TRUSTED_CRAWLER_NETWORKS = (
    YAML.load_file(Rails.root.join('config/google_crawler_networks.yml')).fetch('networks') +
    ENV.fetch('TRUSTED_CRAWLER_NETWORKS', '').split(',').map(&:strip).reject(&:empty?)
  ).map { |cidr| IPAddr.new(cidr) }.freeze
  TRUSTED_CRAWLER_LIMIT_PER_MINUTE = 600

  def self.trusted_crawler?(ip)
    address = IPAddr.new(ip.to_s)
    TRUSTED_CRAWLER_NETWORKS.any? { |range| range.include?(address) }
  rescue IPAddr::Error
    false
  end

  throttle('api/trusted-crawler', limit: TRUSTED_CRAWLER_LIMIT_PER_MINUTE, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/') && trusted_crawler?(req.ip)
  end

  # General API throttle: 60 req/min per IP
  throttle('api/ip', limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/') && !trusted_crawler?(req.ip)
  end

  # Subscriber creation: 5 req/min per IP
  throttle('api/subscribers', limit: 5, period: 1.minute) do |req|
    req.ip if req.path == '/api/v1/subscribers' && req.post?
  end

  # Deal view counter: 10 req/min per IP
  throttle('api/deal_view', limit: 10, period: 1.minute) do |req|
    req.ip if req.path.match?(%r{/api/v1/deals/\d+/view}) && req.post?
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |_env|
    [429, { 'Content-Type' => 'application/json' }, ['{"error":"Rate limit exceeded"}']]
  end
end
