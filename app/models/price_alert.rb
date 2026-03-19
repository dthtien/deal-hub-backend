# frozen_string_literal: true

class PriceAlert < ApplicationRecord
  belongs_to :product

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :target_price, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(triggered: false) }

  def trigger!
    update!(triggered: true, triggered_at: Time.current)
  end
end
