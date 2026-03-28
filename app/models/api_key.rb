# frozen_string_literal: true

class ApiKey < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  before_validation :generate_key, on: :create

  scope :active, -> { where(active: true) }

  def self.authenticate(key_value)
    find_by(key: key_value, active: true)
  end

  private

  def generate_key
    self.key = SecureRandom.hex(32) if key.blank?
  end
end
