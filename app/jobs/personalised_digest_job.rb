# frozen_string_literal: true

class PersonalisedDigestJob < ApplicationJob
  queue_as :default

  def perform
    Subscriber.active.find_each do |subscriber|
      prefs = subscriber.preferences || {}
      frequency = prefs['frequency'] || 'weekly'
      next if frequency == 'never'
      next if frequency == 'weekly' && Time.current.wday != 1 # Send weekly on Monday

      categories = Array(prefs['categories'])
      max_price  = prefs['max_price'].to_f
      max_price  = 500.0 if max_price.zero?

      scope = Product.where(expired: false).where('price <= ?', max_price)

      if categories.any?
        scope = scope.where('categories && array[?]::varchar[]', categories)
      end

      deals = scope.order(deal_score: :desc).limit(10).to_a
      next if deals.empty?

      PersonalisedDigestMailer.digest(subscriber, deals).deliver_later
      Rails.logger.info("[PersonalisedDigest] Queued digest for #{subscriber.email}")
    rescue => e
      Rails.logger.error("[PersonalisedDigest] Error for #{subscriber.id}: #{e.message}")
    end
  end
end
