# frozen_string_literal: true

class CollectionItem < ApplicationRecord
  belongs_to :collection
  belongs_to :product
end
