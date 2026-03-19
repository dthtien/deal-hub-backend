module Crawlers
  class BookingComJob < ApplicationJob
    def perform
      BookingCom::CrawlAll.call
    end
  end
end
