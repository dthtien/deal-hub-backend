require 'rails_helper'

RSpec.describe QuoteItem, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:quote) }
  end
end
