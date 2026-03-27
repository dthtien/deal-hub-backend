# frozen_string_literal: true

class PriceAlert < ApplicationRecord
  belongs_to :product, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :target_price, numericality: { greater_than: 0, allow_nil: true }
  validates :keyword, presence: true, if: -> { product_id.nil? }
  validates :product_id, presence: true, if: -> { keyword.nil? }

  scope :active, -> { where(triggered: false) }
  scope :keyword_alerts, -> { where.not(keyword: nil).where(product_id: nil) }
  scope :price_alerts, -> { where.not(product_id: nil) }

  def trigger!
    update!(triggered: true, triggered_at: Time.current)
  end
end
