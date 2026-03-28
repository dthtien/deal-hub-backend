# frozen_string_literal: true

class CrawlLog < ApplicationRecord
  HEALTH_STATUSES = %w[healthy declining stale unknown].freeze

  validates :store, presence: true

  scope :recent,   -> { order(crawled_at: :desc) }
  scope :healthy,  -> { where(health_status: 'healthy') }
  scope :stale,    -> { where(health_status: 'stale') }
  scope :declining, -> { where(health_status: 'declining') }

  def self.latest_for_store(store_name)
    where(store: store_name).order(crawled_at: :desc).first
  end
end
