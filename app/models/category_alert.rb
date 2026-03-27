# frozen_string_literal: true

class CategoryAlert < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :category, presence: true
  validates :email, uniqueness: { scope: :category, message: 'already subscribed to this category' }
end
