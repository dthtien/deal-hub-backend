require 'rails_helper'

RSpec.describe Crawlers::OfficeWorksJob, type: :job do
  it do
    expect(OfficeWorks::CrawlAll).to receive(:call)

    Crawlers::OfficeWorksJob.new.perform
  end
end
