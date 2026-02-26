# frozen_string_literal: true

FactoryBot.define do
  factory :affiliate_config do
    store { Product::STORES.sample }
    param_name { 'aff' }
    param_value { '12345' }
    active { true }
  end
end
