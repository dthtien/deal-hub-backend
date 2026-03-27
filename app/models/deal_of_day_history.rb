# frozen_string_literal: true

class DealOfDayHistory < ApplicationRecord
  validates :product_id, presence: true
  validates :date, presence: true, uniqueness: true
end
