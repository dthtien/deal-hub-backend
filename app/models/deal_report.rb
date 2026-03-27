# frozen_string_literal: true

class DealReport < ApplicationRecord
  REASONS = %w[expired wrong_price spam broken_link].freeze

  belongs_to :product

  validates :reason, inclusion: { in: REASONS }
  validates :product_id, presence: true
end
