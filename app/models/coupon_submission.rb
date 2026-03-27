# frozen_string_literal: true

class CouponSubmission < ApplicationRecord
  validates :store, :code, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
end
