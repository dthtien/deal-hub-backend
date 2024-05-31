module Crawlers
  class TheGoodGuysJob < ApplicationJob
    def perform
      TheGoodGuys::CrawlAll.call
    end
  end
end
