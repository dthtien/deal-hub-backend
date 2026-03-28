# frozen_string_literal: true

class WatchlistNotifierJob < ApplicationJob
  queue_as :default

  def perform
    store_names = StoreFollow.distinct.pluck(:store_name)

    store_names.each do |store_name|
      new_deals = Product.where(store: store_name)
                         .where('created_at >= ?', 1.hour.ago)
                         .where(expired: false)

      next if new_deals.empty?

      best_deal = new_deals.order(discount: :desc).first

      begin
        WebPushService.send_store_notification(store_name, best_deal, new_deals.count)
      rescue => e
        Rails.logger.error("WatchlistNotifierJob - error for store #{store_name}: #{e.message}")
      end
    end
  end
end
