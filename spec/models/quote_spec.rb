require 'rails_helper'

RSpec.describe Quote, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:quote_items) }
  end

  Quote::STATUSES.each do |status|
    describe "##{status}?" do
      it "returns true if status is #{status}" do
        quote = build(:quote, status: )

        expect(quote.send("#{status}?")).to be_truthy
      end
    end
  end

  describe '#as_json' do
    it 'returns user and quote_items as json' do
      user = create(:user)
      quote = build(:quote, user:)
      quote_item = create(:quote_item, quote:)

      expect(quote.as_json).to include(
        'user' => user.as_json,
        'quote_items' => [quote_item.as_json]
      )
    end
  end
end
