# frozen_string_literal: true

class QuoteItem < ApplicationRecord
  PROVIDERS = [
    AAMI = 'AAMI',
  ].freeze

  belongs_to :quote
end
