# frozen_string_literal: true

module Types
  class StoreType < BaseObject
    field :name,         String,  null: true
    field :deal_count,   Integer, null: true
    field :avg_discount, Float,   null: true
  end
end
