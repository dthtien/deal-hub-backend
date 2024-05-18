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

  def as_json(options = {})
    super(
      options.merge(except: %i[created_at])
    ).merge(store_url:)
  end

  def store_url
    case store
    when OFFICE_WORKS
      "https://www.officeworks.com.au#{store_path}" if store_path.present?
    end
  end
end
