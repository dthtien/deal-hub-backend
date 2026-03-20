# frozen_string_literal: true

class Subscriber < ApplicationRecord
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }

  scope :active, -> { where(status: 'active') }

  before_create :generate_unsubscribe_token
  before_save :downcase_email

  def unsubscribe!
    update!(status: 'unsubscribed')
  end

  private

  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end

  def downcase_email
    self.email = email.downcase
  end
end
