# frozen_string_literal: true

module Types
  class CategoryType < BaseObject
    field :name,  String,  null: true
    field :count, Integer, null: true
  end
end
