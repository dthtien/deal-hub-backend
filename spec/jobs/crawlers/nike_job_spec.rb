# frozen_string_literal: true

RSpec.describe Crawlers::NikeJob, type: :job do
  it do
    expect(Nike::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end


