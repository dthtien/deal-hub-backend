# frozen_string_literal: true

class WatchlistDigestJob < ApplicationJob
  queue_as :low

  def perform
    session_ids = SavedDeal.where.not(session_id: nil)
                           .select(:session_id)
                           .distinct
                           .pluck(:session_id)

    session_ids.each do |session_id|
      begin
        process_digest_for_session(session_id)
      rescue => e
        Rails.logger.error("WatchlistDigestJob - error for session #{session_id}: #{e.message}")
      end
    end
  end

  private

  def process_digest_for_session(session_id)
    saved = SavedDeal.where(session_id: session_id).includes(:product)
    return if saved.empty?

    product_ids = saved.pluck(:product_id)
    cutoff = 7.days.ago

    drops    = 0
    rises    = 0
    unchanged = 0

    product_ids.each do |pid|
      history = PriceHistory.where(product_id: pid)
                            .where('recorded_at >= ?', cutoff)
                            .order(recorded_at: :asc)

      if history.size < 2
        unchanged += 1
        next
      end

      first_price = history.first.price.to_f
      last_price  = history.last.price.to_f

      if last_price < first_price
        drops += 1
      elsif last_price > first_price
        rises += 1
      else
        unchanged += 1
      end
    end

    Rails.logger.info(
      "WatchlistDigestJob - session=#{session_id} | " \
      "Your saved deals: #{drops} price drops, #{rises} price increases, #{unchanged} unchanged"
    )
  end
end
