# frozen_string_literal: true

RSpec.describe Crawlers::MyerJob, type: :job do
  it do
    expect(Myer::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end

