module Crawlers
  class GlueStoreJob < ApplicationJob
    def perform
      GlueStore::CrawlAll.call
    end
  end
end
