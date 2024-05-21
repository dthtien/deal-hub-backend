require 'rails_helper'

RSpec.describe Crawlers::DistributeJob, type: :job do
  it do
    expect(Crawlers::OfficeWorksJob).to receive(:perform_async).once
    expect(Crawlers::JbHifiJob).to receive(:perform_async).once
    expect(Crawlers::GlueStoreJob).to receive(:perform_async).once

    described_class.new.perform
  end
end

