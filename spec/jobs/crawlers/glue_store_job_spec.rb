# frozen_string_literal: true

RSpec.describe Crawlers::GlueStoreJob, type: :job do
  it do
    expect(GlueStore::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end

