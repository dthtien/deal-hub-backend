# frozen_string_literal: true

class CouponScraperJob < ApplicationJob
  queue_as :low

  def perform
    CouponScraper.call
  end
end
