module Crawlers
  class NikeJob < ApplicationJob
    def perform
      Nike::CrawlAll.call
    end
  end
end
