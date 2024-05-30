require 'rails_helper'
require 'rake'
Rails.application.load_tasks

describe 'crawler:crawl_all' do
  it do
    expect(Crawlers::DistributeJob).to receive(:perform_async).once

    Rake::Task['crawler:crawl_all'].invoke
  end
end
