class Quote < ApplicationRecord
  belongs_to :user
  has_many :quote_items
end
