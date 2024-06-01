# frozen_string_literal: true

class Product < ApplicationRecord
  DATE_FORMAT = '%d/%m/%Y %H:%M:%S'
  STORES = [
    OFFICE_WORKS = 'Office Works',
    JB_HIFI = 'JB Hi-Fi',
    GLUE_STORE = 'Glue Store',
    NIKE = 'Nike',
    CULTURE_KINGS = 'Culture Kings',
    JD_SPORTS = 'JD Sports',
    MYER = 'Myer',
    THE_GOOD_GUYS = 'The Good Guys',
    ASOS = 'ASOS'
  ].freeze
  validates :name, presence: true
  validates :price, presence: true
  validates :store_product_id, presence: true
  validates :store, presence: true

  class << self
    def brands
      pluck('DISTINCT(brand)')
    end

    def categories
      pluck('DISTINCT(categories)').flatten.uniq
    end

    def stores
      pluck('DISTINCT(store)')
    end
  end

  def as_json(options = {})
    super(options).merge(
      store_url:,
      'updated_at' => updated_at.strftime(DATE_FORMAT),
      'created_at' => created_at.strftime(DATE_FORMAT)
    )
  end

  def store_url
    return if store_path.blank?

    case store
    when OFFICE_WORKS
      "https://www.officeworks.com.au#{store_path}"
    when JB_HIFI
      "https://www.jbhifi.com.au/products/#{store_path}"
    when GLUE_STORE
      "https://www.gluestore.com.au/products/#{store_path}"
    when NIKE
      "https://www.nike.com/#{store_path}"
    when CULTURE_KINGS
      "https://www.culturekings.com.au/products/#{store_path}"
    when JD_SPORTS
      "https://www.jd-sports.com.au#{store_path}"
    when MYER
      "https://www.myer.com.au/p/#{store_path}"
    when ASOS
      "https://www.asos.com/au/#{store_path}"
    when THE_GOOD_GUYS
      store_path
    end
  end
end
