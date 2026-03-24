# frozen_string_literal: true

class Vote < ApplicationRecord
  belongs_to :product

  validates :session_id, presence: true
  validates :value, inclusion: { in: [1, -1] }
  validates :session_id, uniqueness: { scope: :product_id }
end
