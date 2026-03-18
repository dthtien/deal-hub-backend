# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name { 'MyString' }
    price { 1.5 }
    store_product_id { SecureRandom.uuid }
    store { %w[asos culture_kings foot_locker nike myer the_iconic].sample }
    store_path { "https://www.example.com/product/#{SecureRandom.hex(4)}" }
    image_url { "https://images.example.com/#{SecureRandom.hex(4)}.jpg" }
  end
end
