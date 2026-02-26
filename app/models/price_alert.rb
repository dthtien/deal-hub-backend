# frozen_string_literal: true

class PriceAlert < ApplicationRecord
  belongs_to :product

  enum :status, { active: 0, triggered: 1, cancelled: 2 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :target_price, presence: true, numericality: { greater_than: 0 }
  validates :email, uniqueness: { scope: :product_id, message: 'already has an alert for this product' }
end
