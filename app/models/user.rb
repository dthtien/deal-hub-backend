# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password validations: false
  has_many :quotes
  has_many :saved_deals, dependent: :destroy
  has_many :saved_products, through: :saved_deals, source: :product

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }

  def self.from_google(auth)
    user = find_or_initialize_by(email: auth['email'].downcase)
    user.assign_attributes(
      google_uid: auth['uid'],
      provider: 'google',
      first_name: auth['first_name'],
      last_name: auth['last_name'],
      avatar_url: auth['avatar_url']
    )
    user.save!
    user
  end

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
