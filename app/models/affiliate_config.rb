# frozen_string_literal: true

class AffiliateConfig < ApplicationRecord
  STORES = Product::STORES

  validates :store, presence: true, inclusion: { in: STORES }, uniqueness: true
  validates :param_name, presence: true
  validates :param_value, presence: true

  scope :active, -> { where(active: true) }

  def self.as_map
    active.each_with_object({}) do |config, hash|
      hash[config.store] = { param: config.param_name, value: config.param_value }
    end
  end
end
