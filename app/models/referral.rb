# frozen_string_literal: true

class Referral < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :click_count, numericality: { greater_than_or_equal_to: 0 }
  validates :conversion_count, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_code, on: :create

  REWARD_PER_CONVERSION = 5.freeze

  def self.find_or_create_for_session(session_id)
    find_by(session_id: session_id) || create!(session_id: session_id)
  end

  def estimated_reward
    conversion_count * REWARD_PER_CONVERSION
  end

  def record_conversion!
    increment!(:conversion_count)
    update!(converted_at: Time.current) if converted_at.nil?
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(8).upcase
  end
end
