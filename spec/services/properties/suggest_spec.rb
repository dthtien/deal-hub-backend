# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Properties::Suggest, type: :service do
  let(:address) { '123 Main St, Springfield, IL' }
  let(:service) { described_class.new(address) }

  describe '#call' do
    it 'returns suggestions for the given address' do
      allow_any_instance_of(Properties::SuggestionCrawler).to receive(:call).and_return(true)
      allow_any_instance_of(Properties::SuggestionCrawler).to receive(:data).and_return([
        {
          'display' => { 'text' => '123 Main St, Springfield, IL' },
          'source' => {
            'state' => 'IL',
            'suburb' => 'Springfield',
            'postcode' => '62701',
            'streetName' => 'Main St',
            'streetNumber' => '123'
          },
          'id' => 1
        }
      ])

      result = service.call

      expect(result.data).to eq([
        {
          address: '123 Main St, Springfield, IL',
          id: 1,
          path: 'il/springfield-62701/main-st/123-pid-1/'
        }]
      )
    end
  end
end
