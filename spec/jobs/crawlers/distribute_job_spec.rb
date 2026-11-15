require 'rails_helper'

RSpec.describe Crawlers::DistributeJob, type: :job do
  it do
    expect(Crawlers::OfficeWorksJob).to receive(:perform_async).once
    expect(Crawlers::JbHifiJob).to receive(:perform_async).once
    expect(Crawlers::GlueStoreJob).not_to receive(:perform_async) # paused, see DistributeJob
    # expect(Crawlers::NikeJob).to receive(:perform_async).once
    expect(Crawlers::CultureKingsJob).to receive(:perform_async).once
    expect(Crawlers::JdSportsJob).to receive(:perform_async).once
    expect(Crawlers::MyerJob).not_to receive(:perform_async) # paused, see DistributeJob
    expect(Crawlers::TheGoodGuysJob).to receive(:perform_async).once
    expect(Crawlers::AsosJob).to receive(:perform_async).once
    expect(Crawlers::TheIconicJob).to receive(:perform_async).once

    described_class.new.perform
  end
end

