# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "a+#{n}@email.com" }
    first_name { 'John' }
    last_name { 'Doe' }
    date_of_birth { '1990-01-01' }
  end
end
