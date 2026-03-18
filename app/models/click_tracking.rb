class ClickTracking < ApplicationRecord
  belongs_to :product

  validates :product_id, presence: true

  scope :recent, -> { order(clicked_at: :desc) }
  scope :by_store, ->(store) { where(store: store) }
  scope :today, -> { where(clicked_at: Time.current.beginning_of_day..) }
end
