# frozen_string_literal: true

Gush.configure do |config|
  config.redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'
end
