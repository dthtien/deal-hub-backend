module Crawlers
  class OfficeWorksJob < ApplicationJob
    def perform
      OfficeWorks::CrawlAll.call
    end
  end
end
