require 'rails_helper'

RSpec.describe Crawlers::OfficeWorksJob, type: :job do
  it do
    expect(OfficeWorks::CrawlAll).to receive(:call)

    described_class.new.perform
  end
end
