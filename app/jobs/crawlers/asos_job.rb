module Crawlers
  class AsosJob < ApplicationJob
    def perform
      Asos::CrawlAll.call
    end
  end
end
