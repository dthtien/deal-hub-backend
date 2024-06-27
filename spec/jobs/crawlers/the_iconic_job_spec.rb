require 'rails_helper'

RSpec.describe Crawlers::TheIconicJob, type: :job do
  it do
    expect(TheIconic::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end


