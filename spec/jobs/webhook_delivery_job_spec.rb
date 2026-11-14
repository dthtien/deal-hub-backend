# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhookDeliveryJob, type: :job do
  let(:url) { 'https://example.com/hook' }
  let(:webhook) { Webhook.create!(url: url, secret: 'secret', events: ['deal.new']) }
  # String keys, as the job receives them from Sidekiq
  let(:payload) { { 'event' => 'deal.new', 'product_id' => 1 } }

  describe '#perform' do
    it 'posts the signed payload and records the delivery' do
      signature = OpenSSL::HMAC.hexdigest('SHA256', 'secret', payload.to_json)
      stub = stub_request(:post, url)
             .with(
               body: payload.to_json,
               headers: { 'X-OzVFY-Event' => 'deal.new', 'X-OzVFY-Signature' => "sha256=#{signature}" }
             )
             .to_return(status: 200)

      expect { described_class.new.perform(webhook.id, 'deal.new', payload) }
        .to change(WebhookDelivery, :count).by(1)

      expect(stub).to have_been_requested
      delivery = WebhookDelivery.last
      expect(delivery.webhook_id).to eq(webhook.id)
      expect(delivery.response_status).to eq(200)
      expect(delivery.failed).to be false
      expect(delivery.payload).to eq(payload)
    end

    it 'records a failed delivery when the endpoint cannot be reached' do
      stub_request(:post, url).to_timeout

      expect { described_class.new.perform(webhook.id, 'deal.new', payload) }
        .to change(WebhookDelivery, :count).by(1)

      delivery = WebhookDelivery.last
      expect(delivery.failed).to be true
      expect(delivery.delivered_at).to be_nil
    end

    it 'does nothing for an inactive webhook' do
      webhook.update!(active: false)

      expect { described_class.new.perform(webhook.id, 'deal.new', payload) }
        .not_to change(WebhookDelivery, :count)
    end
  end
end
