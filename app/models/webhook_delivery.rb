# frozen_string_literal: true

class WebhookDelivery < ApplicationRecord
  belongs_to :webhook, optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(failed: true) }
  scope :successful, -> { where(failed: false) }
end
