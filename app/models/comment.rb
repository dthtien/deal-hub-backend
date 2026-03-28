class Comment < ApplicationRecord
  belongs_to :product

  validates :body, presence: true, length: { maximum: 1000 }
  validates :status, inclusion: { in: %w[active flagged approved] }

  before_validation :set_default_name
  after_create :queue_moderation

  scope :active_comments, -> { where(status: %w[active approved]) }
  scope :flagged_comments, -> { where(status: 'flagged') }

  private

  def set_default_name
    self.name = 'Anonymous' if name.blank?
    self.status ||= 'active'
  end

  def queue_moderation
    CommentModerationJob.perform_later(id)
  end
end
