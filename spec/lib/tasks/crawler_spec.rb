require 'rails_helper'
require 'rake'
Rails.application.load_tasks

describe 'crawler:crawl_all' do
  it do
    expect(Crawlers::OfficeWorksJob).to receive(:perform_async).once
    expect(Crawlers::JbHifiJob).to receive(:perform_async).once
    expect(Crawlers::GlueStoreJob).to receive(:perform_async).once
    expect(Crawlers::NikeJob).to receive(:perform_async).once

    Rake::Task['crawler:crawl_all'].invoke
  end
end
