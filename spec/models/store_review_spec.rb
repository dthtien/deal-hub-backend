require 'rails_helper'

RSpec.describe StoreReview, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      review = build(:store_review)
      expect(review).to be_valid
    end

    it 'requires store_name' do
      review = build(:store_review, store_name: '')
      expect(review).not_to be_valid
    end

    it 'requires rating' do
      review = build(:store_review, rating: nil)
      expect(review).not_to be_valid
    end

    it 'validates rating is between 1 and 5' do
      expect(build(:store_review, rating: 0)).not_to be_valid
      expect(build(:store_review, rating: 6)).not_to be_valid
      expect(build(:store_review, rating: 1)).to be_valid
      expect(build(:store_review, rating: 5)).to be_valid
    end

    it 'requires session_id' do
      review = build(:store_review, session_id: '')
      expect(review).not_to be_valid
    end
  end

  describe '.avg_rating_for' do
    it 'returns average rating for a store' do
      create(:store_review, store_name: 'Kmart', rating: 4)
      create(:store_review, store_name: 'Kmart', rating: 2)
      expect(StoreReview.avg_rating_for('Kmart')).to eq(3.0)
    end

    it 'returns 0.0 when no reviews' do
      expect(StoreReview.avg_rating_for('NoStore')).to eq(0.0)
    end
  end

  describe '.count_for' do
    it 'returns review count for a store' do
      create_list(:store_review, 3, store_name: 'Kmart')
      expect(StoreReview.count_for('Kmart')).to eq(3)
    end
  end
end
