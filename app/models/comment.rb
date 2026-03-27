class Comment < ApplicationRecord
  belongs_to :product

  validates :body, presence: true, length: { maximum: 1000 }

  before_validation :set_default_name

  private

  def set_default_name
    self.name = 'Anonymous' if name.blank?
  end
end
