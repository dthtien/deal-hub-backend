# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Properties::SuggestionCrawler do
  let(:query) { 'Sydney' }
  let(:crawler) { described_class.new(query) }

  describe '#call' do
    before do
      stub_request(:get, %r{\Ahttps://suggest.realestate.com.au/consumer-suggest/suggestions})
        .with(query: hash_including({ query: query }))
        .to_return(status: 200, body: File.read('spec/fixtures/properties/suggestions/success.json'))

      crawler.call
    end

    it 'fetches suggestions based on the query' do
      expect(crawler.data.size).to eq(6)
      expect(crawler.data.first).to include(
        '_links',
        'display',
        'id',
        'source'
      )
    end
  end
end
