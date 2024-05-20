# frozen_string_literal: true

class Product < ApplicationRecord
  DATE_FORMAT = '%d/%m/%Y %H:%M:%S'
  STORES = [
    OFFICE_WORKS = 'Office Works',
    JB_HIFI = 'JB Hi-Fi'
  ].freeze
  validates :name, presence: true
  validates :price, presence: true
  validates :store_product_id, presence: true
  validates :store, presence: true

  def as_json(options = {})
    super(options).merge(
      store_url:,
      'updated_at' => updated_at.strftime(DATE_FORMAT),
      'created_at' => created_at.strftime(DATE_FORMAT)
    )
  end

  def store_url
    case store
    when OFFICE_WORKS
      "https://www.officeworks.com.au#{store_path}" if store_path.present?
    end
  end
end
