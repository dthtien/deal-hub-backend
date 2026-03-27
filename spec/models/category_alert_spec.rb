require 'rails_helper'

RSpec.describe CategoryAlert, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      alert = build(:category_alert)
      expect(alert).to be_valid
    end

    it 'requires email' do
      alert = build(:category_alert, email: '')
      expect(alert).not_to be_valid
    end

    it 'requires a valid email format' do
      alert = build(:category_alert, email: 'not-an-email')
      expect(alert).not_to be_valid
    end

    it 'requires category' do
      alert = build(:category_alert, category: '')
      expect(alert).not_to be_valid
    end

    it 'enforces uniqueness of email scoped to category' do
      create(:category_alert, email: 'test@example.com', category: "Women's Fashion")
      dup = build(:category_alert, email: 'test@example.com', category: "Women's Fashion")
      expect(dup).not_to be_valid
    end

    it 'allows same email with different category' do
      create(:category_alert, email: 'test@example.com', category: "Women's Fashion")
      other = build(:category_alert, email: 'test@example.com', category: 'Electronics')
      expect(other).to be_valid
    end
  end
end
