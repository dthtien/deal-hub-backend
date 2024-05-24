# frozen_string_literal: true

RSpec.describe Crawlers::CultureKingsJob, type: :job do
  it do
    expect(CultureKings::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end
