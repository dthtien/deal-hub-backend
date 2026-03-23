# frozen_string_literal: true

module Crawlers
  class GoodBuyzJob < ApplicationJob
    def perform
      GoodBuyz::CrawlAll.call
    end
  end
end
