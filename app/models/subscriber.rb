# frozen_string_literal: true

class Subscriber < ApplicationRecord
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }

  scope :active, -> { where(status: 'active') }

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
