# frozen_string_literal: true

class AiDealAnalysis < ApplicationRecord
  belongs_to :product

  RECOMMENDATIONS = %w[BUY_NOW GOOD_DEAL WAIT OVERPRICED].freeze
  CONFIDENCE = %w[HIGH MEDIUM LOW].freeze

  # Re-analyse if older than 6 hours
  STALE_AFTER = 6.hours

  def stale?
    analysed_at < STALE_AFTER.ago
  end

  def fresh?
    !stale?
  end
end
