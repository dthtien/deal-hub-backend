# frozen_string_literal: true

FactoryBot.define do
  factory :quote_item do
    quote

    provider { 'Suncorp' }
    annual_price { 1000 }
    monthly_price { 100 }
    response_details { { 'vehicleDetails' => { 'make' => 'Toyota', 'model' => 'Corolla' } } }
  end
end
