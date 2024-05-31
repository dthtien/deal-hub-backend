require 'rails_helper'

RSpec.describe Crawlers::TheGoodGuysJob, type: :job do
  it do
    expect(TheGoodGuys::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end

