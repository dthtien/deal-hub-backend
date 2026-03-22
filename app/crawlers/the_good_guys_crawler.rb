# frozen_string_literal: true
# The Good Guys migrated from Firebase/Firestore to Shopify Oxygen.
# Their Shopify collections API is not publicly accessible.
# This crawler is temporarily disabled until a new data source is found.

class TheGoodGuysCrawler
  attr_reader :data

  def initialize
    @data = []
  end

  def crawl_all
    Rails.logger.warn 'TheGoodGuysCrawler: disabled — site migrated, endpoint unavailable'
    self
  end
end
