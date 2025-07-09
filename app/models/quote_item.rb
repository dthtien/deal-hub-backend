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
    COMPARE_THE_MARKET = 'Compare the Market'
  ].freeze

  belongs_to :quote
  enum :status, { pending: 0, completed: 1, failed: 2 }

  def as_json(options = {})
    super(options).merge(
      'created_at' => created_at&.strftime('%Y-%m-%d %H:%M:%S')
    )
  end
end
