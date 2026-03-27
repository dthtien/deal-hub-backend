# frozen_string_literal: true

module Crawlers
  class LornaJaneJob < ApplicationJob
    sidekiq_options retry: 2

    def perform
      LornaJane::CrawlAll.call
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Net::ReadTimeout => e
      Rails.logger.error "LornaJaneJob: network error, skipping. #{e.message}"
    end
  end
end
