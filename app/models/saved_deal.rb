# frozen_string_literal: true

class SavedDeal < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :product

  validates :product_id, uniqueness: { scope: :user_id, message: 'already saved this deal', conditions: -> { where.not(user_id: nil) } }
  validates :product_id, uniqueness: { scope: :session_id, message: 'already saved this deal', conditions: -> { where.not(session_id: nil) } }
  validate :user_or_session_present

  private

  def user_or_session_present
    errors.add(:base, 'user_id or session_id required') if user_id.blank? && session_id.blank?
  end
end
