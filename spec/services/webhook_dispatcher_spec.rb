# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhookDispatcher do
  # Symbol keys, as every caller passes them
  let(:payload) { { event: 'deal.new', product_id: 1, price: 9.99 } }

  def make_webhook(attrs = {})
    Webhook.create!({ url: 'https://example.com/hook', secret: 'secret', events: ['deal.new'] }.merge(attrs))
  end

  describe '.dispatch' do
    it 'queues one delivery job per active webhook subscribed to the event' do
      webhook = make_webhook
      make_webhook(events: ['deal.expired'])
      make_webhook(active: false)

      expect { described_class.dispatch('deal.new', payload) }
        .to change { WebhookDeliveryJob.jobs.size }.by(1)

      expect(WebhookDeliveryJob.jobs.last['args']).to eq(
        [webhook.id, 'deal.new', { 'event' => 'deal.new', 'product_id' => 1, 'price' => 9.99 }]
      )
    end

    it 'queues nothing when no webhook is subscribed to the event' do
      make_webhook(events: ['deal.expired'])

      expect { described_class.dispatch('deal.new', payload) }
        .not_to change { WebhookDeliveryJob.jobs.size }
    end

    it 'queues the job on a queue the Sidekiq process works' do
      make_webhook
      described_class.dispatch('deal.new', payload)

      config = YAML.load_file(Rails.root.join('config/sidekiq.yml')).deep_symbolize_keys
      worked_queues = config[:queues].map { |queue| Array(queue).first.to_s }

      expect(worked_queues).to include(WebhookDeliveryJob.jobs.last['queue'])
    end
  end
end
