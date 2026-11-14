# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeeklyNewsletterJob, type: :job do
  let(:mail_jobs) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper.jobs }

  it 'queues one digest email per active subscriber' do
    create(:product, discount: 25, old_price: 2.0, expired: false)
    Subscriber.create!(email: 'reader@example.com', status: 'active')
    Subscriber.create!(email: 'gone@example.com', status: 'unsubscribed')

    # Raised ActiveJob::SerializationError when the deals were passed as Relations
    expect { described_class.new.perform }.to change { mail_jobs.size }.by(1)
  end

  it 'queues nothing when there are no deals' do
    Subscriber.create!(email: 'reader@example.com', status: 'active')

    expect { described_class.new.perform }.not_to(change { mail_jobs.size })
  end
end
