# frozen_string_literal: true

class Coupon < ApplicationRecord
  validates :store, :code, presence: true
  validates :discount_type, inclusion: { in: %w[percent fixed] }, allow_nil: true

  scope :active, -> { where(active: true).where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :for_store, ->(store) { where('LOWER(store) = ?', store.downcase) }
  scope :verified_first, -> { order(verified: :desc, use_count: :desc, created_at: :desc) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def active?
    self[:active] == true && !expired?
  end

  def discount_label
    return nil unless discount_value.present?
    discount_type == 'fixed' ? "Save $#{discount_value.to_i}" : "#{discount_value.to_i}% off"
  end

  def min_purchase
    return min_purchase_amount.to_f if respond_to?(:min_purchase_amount) && min_purchase_amount.present?
    # fall back to parsing the legacy minimum_spend string if present
    return nil unless minimum_spend.present?
    minimum_spend.to_s.gsub(/[^0-9.]/, '').to_f
  end
end
