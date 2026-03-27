# frozen_string_literal: true

module Crawlers
  class BeginningBoutiqueJob < ApplicationJob
    def perform
      BeginningBoutique::CrawlAll.call
    end
  end
end
