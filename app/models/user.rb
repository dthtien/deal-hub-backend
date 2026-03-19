# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :quotes
  has_many :saved_deals, dependent: :destroy
  has_many :saved_products, through: :saved_deals, source: :product

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
