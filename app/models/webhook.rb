# frozen_string_literal: true

class Webhook < ApplicationRecord
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :secret, presence: true

  scope :active_for, ->(event) { where(active: true).where('? = ANY(events)', event) }

  before_create :generate_secret_if_blank

  private

  def generate_secret_if_blank
    self.secret = SecureRandom.hex(32) if secret.blank?
  end
end
