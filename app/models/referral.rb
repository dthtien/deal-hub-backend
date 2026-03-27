# frozen_string_literal: true

class Referral < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :click_count, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_code, on: :create

  def self.find_or_create_for_session(session_id)
    find_by(session_id: session_id) || create!(session_id: session_id)
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(8).upcase
  end
end
