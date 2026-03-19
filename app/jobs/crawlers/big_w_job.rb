module Crawlers
  class BigWJob < ApplicationJob
    def perform
      BigW::CrawlAll.call
    end
  end
end
