# frozen_string_literal: true

# Run daily after scraper finishes to snapshot current prices
class RecordPriceHistoryJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current

    Product.find_each do |product|
      PriceHistory.find_or_create_by(product: product, recorded_on: today) do |h|
        h.price = product.price
      end
    end
  end
end
