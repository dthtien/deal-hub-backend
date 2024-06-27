module Crawlers
  class TheIconicJob < ApplicationJob
    def perform
      TheIconic::CrawlAll.call
    end
  end
end
