# frozen_string_literal: true

class PriceHistory < ApplicationRecord
  belongs_to :product

  validates :price, presence: true
  validates :recorded_at, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :last_90_days, -> { where(recorded_at: 90.days.ago..) }
end
