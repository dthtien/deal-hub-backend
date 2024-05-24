module Crawlers
  class CultureKingsJob < ApplicationJob
    def perform
      CultureKings::CrawlAll.call
    end
  end
end
