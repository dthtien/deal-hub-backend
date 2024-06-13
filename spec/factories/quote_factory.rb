# frozen_string_literal: true

FactoryBot.define do
  factory :quote do
    user
    status { 'pending' }
    policy_start_date { '2022-01-01' }
    current_insurer { 'AAMI' }
    state { 'VIC' }
    suburb { 'Ardeer' }
    postcode { '3022' }
    address_line1 { '78 Esmond Street' }
    plate { 'ZZB619' }
    financed { false }
    primary_usage { 'private' }
    days_wfh { '1_to_2' }
    peak_hour_driving { false }
    cover_type { 'comprehensive' }
    driver_dob { '1990-09-01' }
    driver_gender { 'Male' }
    has_claim_occurrences { false }
    claim_occurrences { [] }
    additional_drivers { [] }
    parking { { indicator: 'same_suburb' } }
    km_per_year { 4000 }
  end
end
