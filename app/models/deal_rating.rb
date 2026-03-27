# frozen_string_literal: true

class DealRating < ApplicationRecord
  belongs_to :product

  validates :session_id, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :session_id, uniqueness: { scope: :product_id }
end
