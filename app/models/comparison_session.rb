# frozen_string_literal: true

class ComparisonSession < ApplicationRecord
  validates :session_id, presence: true
  validates :product_ids, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
