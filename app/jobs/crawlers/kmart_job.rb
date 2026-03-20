module Crawlers
  class KmartJob < ApplicationJob
    sidekiq_options retry: 2

    def perform
      Kmart::CrawlAll.call
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Net::ReadTimeout => e
      Rails.logger.error "KmartJob: network error, skipping. #{e.message}"
    end
  end
end
