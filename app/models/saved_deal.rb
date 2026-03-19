# frozen_string_literal: true

class SavedDeal < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :user_id, uniqueness: { scope: :product_id, message: 'already saved this deal' }
end
