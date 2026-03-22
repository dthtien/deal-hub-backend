# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TheGoodGuysCrawler do
  let(:crawler) { described_class.new }

  describe '#crawl_all' do
    it 'returns empty data gracefully (site migrated, crawler disabled)' do
      crawler.crawl_all
      expect(crawler.data).to eq([])
    end
  end
end
