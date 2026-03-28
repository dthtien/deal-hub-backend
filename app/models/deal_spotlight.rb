# frozen_string_literal: true

class DealSpotlight < ApplicationRecord
  belongs_to :product

  validates :title, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :active_now, -> {
    where(active: true).where("featured_until IS NULL OR featured_until > ?", Time.current)
  }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  def as_json(options = {})
    super(options).merge(
      product: product.as_json
    )
  end
end
