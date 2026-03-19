module Crawlers
  class KmartJob < ApplicationJob
    def perform
      Kmart::CrawlAll.call
    end
  end
end
