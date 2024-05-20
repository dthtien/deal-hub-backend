# frozen_string_literal: true

RSpec.describe Crawlers::JbHifiJob, type: :job do
  it do
    expect(JbHifi::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end

