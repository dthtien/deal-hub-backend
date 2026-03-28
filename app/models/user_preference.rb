# frozen_string_literal: true

class UserPreference < ApplicationRecord
  self.table_name = 'user_preferences'

  validates :session_id, presence: true, uniqueness: true
end
