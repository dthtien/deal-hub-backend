module Crawlers
  class BigWJob < ApplicationJob
    sidekiq_options retry: 2

    def perform
      BigW::CrawlAll.call
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Net::ReadTimeout => e
      Rails.logger.error "BigWJob: network error, skipping. #{e.message}"
    end
  end
end
