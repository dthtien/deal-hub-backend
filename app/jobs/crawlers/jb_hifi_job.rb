module Crawlers
  class JbHifiJob < ApplicationJob
    def perform
      JbHifi::CrawlAll.call
    end
  end
end
