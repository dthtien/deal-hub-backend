# frozen_string_literal: true

class DealScoreHistory < ApplicationRecord
  belongs_to :product, optional: true

  validates :score, presence: true
  validates :recorded_at, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
end
