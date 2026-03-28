# frozen_string_literal: true

class PersonalisedEmailJob < ApplicationJob
  queue_as :default

  VALID_STATES = %w[NSW VIC QLD WA SA TAS ACT NT].freeze

  def perform
    # Group subscribers by preferences to batch similar groups
    grouped = Hash.new { |h, k| h[k] = [] }

    Subscriber.active.find_each do |subscriber|
      prefs = subscriber.preferences || {}
      categories = Array(prefs['categories']).first(5).sort
      stores = Array(prefs['stores']).first(5).sort
      key = [categories, stores].to_json
      grouped[key] << subscriber
    rescue => e
      Rails.logger.error("[PersonalisedEmailJob] Error grouping subscriber #{subscriber.id}: #{e.message}")
    end

    grouped.each do |pref_key, subscribers|
      prefs = JSON.parse(pref_key)
      categories = prefs[0]
      stores = prefs[1]

      deals = find_matching_deals(categories, stores)
      next if deals.empty?

      subscribers.each do |subscriber|
        SubscriberMailer.personalised_deals(subscriber, deals).deliver_later
        Rails.logger.info("[PersonalisedEmailJob] Queued personalised email for #{subscriber.email}")
      rescue => e
        Rails.logger.error("[PersonalisedEmailJob] Error queueing for subscriber #{subscriber.id}: #{e.message}")
      end
    end
  end

  private

  def find_matching_deals(categories, stores)
    scope = Product.where(expired: false).where('discount > 0')

    if categories.any? || stores.any?
      cat_scope   = categories.any? ? Product.where('categories && array[?]::varchar[]', categories) : Product.none
      store_scope = stores.any? ? Product.where(store: stores) : Product.none
      scope = scope.merge(cat_scope.or(store_scope))
    end

    scope.order(deal_score: :desc, discount: :desc).limit(5).to_a
  end
end
