# frozen_string_literal: true

RSpec.describe Crawlers::AsosJob, type: :job do
  it do
    expect(Asos::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end

