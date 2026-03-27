# frozen_string_literal: true

class WebhookDispatcher
  def self.dispatch(event, payload)
    Webhook.active_for(event).find_each do |webhook|
      WebhookDeliveryJob.perform_later(webhook.id, event, payload)
    end
  end
end
