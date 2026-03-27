# frozen_string_literal: true

module Crawlers
  class UniversalStoreJob < ApplicationJob
    sidekiq_options retry: 2

    def perform
      UniversalStore::CrawlAll.call
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Net::ReadTimeout => e
      Rails.logger.error "UniversalStoreJob: network error, skipping. #{e.message}"
    end
  end
end
