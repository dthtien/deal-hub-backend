require 'ipaddr'

class Rack::Attack
  # Count in Redis when it is available, so every web process and every web
  # pod shares the same counters. Without this each pod keeps its own count
  # and the real limits are multiplied by the number of pods.
  if ENV['REDIS_URL'].present?
    self.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'], namespace: 'rack-attack')
  end

  # Networks that have sent swarms of crawler traffic: thousands of addresses,
  # each making only a few requests, so the per-address limit never applies.
  # Every address in one of these networks shares that network's allowance.
  # Override with THROTTLED_NETWORKS, a comma separated list of CIDR ranges
  # (set it to an empty string to switch this off).
  #   43.160.0.0/12 and 161.120.176.0/20: Tencent Cloud (Aceville Pte Ltd)
  THROTTLED_NETWORKS = ENV.fetch('THROTTLED_NETWORKS', '43.160.0.0/12,161.120.176.0/20')
                          .split(',').map(&:strip).reject(&:empty?)
                          .to_h { |cidr| [cidr, IPAddr.new(cidr)] }.freeze

  # Allowance per network. All three apply at once.
  NETWORK_LIMITS = [[10, 1.minute], [100, 20.minutes], [200, 1.hour]].freeze

  def self.throttled_network(ip)
    address = IPAddr.new(ip.to_s)
    THROTTLED_NETWORKS.each { |cidr, range| return cidr if range.include?(address) }
    nil
  rescue IPAddr::Error
    nil
  end

  NETWORK_LIMITS.each do |limit, period|
    throttle("network/#{period.to_i}s", limit: limit, period: period) do |req|
      throttled_network(req.ip) if req.path.start_with?('/api/')
    end
  end

  # General API throttle: 60 req/min per IP
  throttle('api/ip', limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
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
