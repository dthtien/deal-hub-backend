# frozen_string_literal: true

class StoreFollow < ApplicationRecord
  validates :session_id, presence: true
  validates :store_name, presence: true
  validates :store_name, uniqueness: { scope: :session_id }
end
