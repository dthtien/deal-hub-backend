module Crawlers
  class JdSportsJob < ApplicationJob
    def perform
      JdSports::CrawlAll.call
    end
  end
end
