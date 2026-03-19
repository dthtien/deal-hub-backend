# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name { 'MyString' }
    price { 1.5 }
    store_product_id { SecureRandom.uuid }
    store { Product::STORES.sample }
  end
end
