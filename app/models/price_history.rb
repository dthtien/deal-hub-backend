# frozen_string_literal: true

class PriceHistory < ApplicationRecord
  belongs_to :product

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :recorded_on, presence: true
  validates :product_id, uniqueness: { scope: :recorded_on }

  scope :recent, ->(days = 90) { where(recorded_on: days.days.ago.to_date..) }
  scope :chronological, -> { order(:recorded_on) }
end
