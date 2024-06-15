# frozen_string_literal: true
#
class Quote < ApplicationRecord
  belongs_to :user
  has_many :quote_items

  STATUSES = [
    INITIATED = 'initiated',
    PENDING = 'pending',
    COMPLETED = 'completed'
  ].freeze
end
