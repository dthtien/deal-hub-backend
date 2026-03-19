# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password validations: false
  has_many :quotes
  has_many :saved_deals, dependent: :destroy
  has_many :saved_products, through: :saved_deals, source: :product

  validates :email, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
