class Rack::Attack
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
