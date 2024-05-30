module Crawlers
  class MyerJob < ApplicationJob
    def perform
      Myer::CrawlAll.call
    end
  end
end
