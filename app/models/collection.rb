# frozen_string_literal: true

class Collection < ApplicationRecord
  has_many :collection_items, dependent: :destroy
  has_many :products, through: :collection_items

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :active, -> { where(active: true) }

  def product_count
    collection_items.count
  end
end
