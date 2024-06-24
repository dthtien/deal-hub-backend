# frozen_string_literal: true
#
class Quote < ApplicationRecord
  belongs_to :user
  has_many :quote_items

  STATUSES = [
    INITIATED = 'initiated',
    PENDING = 'pending',
    FAILED = 'failed',
    COMPLETED = 'completed'
  ].freeze

  def failed?
    status == FAILED
  end

  def completed?
    status == COMPLETED
  end

  def pending?
    status == PENDING
  end

  def initiated?
    status == INITIATED
  end

  def as_json(options = {})
    super(options).merge(
      'user' => user.as_json,
      'quote_items' => quote_items.order(annual_price: :asc).as_json
    )
  end
end
