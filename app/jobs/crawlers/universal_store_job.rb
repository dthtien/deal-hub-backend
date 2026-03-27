# frozen_string_literal: true

module Crawlers
  class UniversalStoreJob < ApplicationJob
    def perform
      UniversalStore::CrawlAll.call
    end
  end
end
