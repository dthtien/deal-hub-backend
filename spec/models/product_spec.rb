# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Product, :model, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_presence_of(:store_product_id) }
    it { is_expected.to validate_presence_of(:store) }
  end
end
