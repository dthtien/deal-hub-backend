# frozen_string_literal: true
#
class Product < ApplicationRecord
  STORES = [
    OFFICE_WORKS = 'Office Works'
  ].freeze
  validates :name, presence: true
  validates :price, presence: true
  validates :store_product_id, presence: true
  validates :store, presence: true
end
