# frozen_string_literal: true

RSpec.describe Crawlers::JdSportsJob, type: :job do
  it do
    expect(JdSports::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end
