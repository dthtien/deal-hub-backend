# frozen_string_literal: true

class WebhookDispatcher
  def self.dispatch(event, payload)
    # Sidekiq only takes JSON-native arguments (string keys, no symbols), so the
    # payload is round-tripped through JSON before it is enqueued.
    json_payload = JSON.parse(payload.to_json)

    Webhook.active_for(event).find_each do |webhook|
      WebhookDeliveryJob.perform_async(webhook.id, event, json_payload)
    end
  end
end
