# frozen_string_literal: true

class DealSubmission < ApplicationRecord
  validates :title, presence: true
  validates :url,   presence: true, format: { with: URI::regexp(%w[http https]), message: 'must be a valid URL' }
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending,  -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
end
