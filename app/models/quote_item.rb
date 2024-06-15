# frozen_string_literal: true

class QuoteItem < ApplicationRecord
  PROVIDERS = [
    AAMI = 'AAMI',
    BUDGET_DIRECT = 'Budget Direct',
    VIRGIN_MONEY = 'Virgin Money',
    EVERYDAY_INSURANCE = 'Everyday Insurance',
    OCEANIA = 'Oceania',
    OZICARE = 'Ozicare',
    HUDDLE = 'Huddle',
    CARPEESH = 'Carpeesh',
  ].freeze

  belongs_to :quote
end
