# frozen_string_literal: true

class StoreReview < ApplicationRecord
  validates :store_name, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5, message: 'must be between 1 and 5' }
  validates :session_id, presence: true

  scope :for_store, ->(name) { where(store_name: name) }

  def self.avg_rating_for(store_name)
    where(store_name: store_name).average(:rating)&.round(1) || 0.0
  end

  def self.count_for(store_name)
    where(store_name: store_name).count
  end
end
