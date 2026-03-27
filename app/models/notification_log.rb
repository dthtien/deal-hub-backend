# frozen_string_literal: true

class NotificationLog < ApplicationRecord
  STATUSES = %w[sent failed].freeze

  validates :notification_type, presence: true
  validates :recipient, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
end
