# frozen_string_literal: true

class CommentModerationJob < ApplicationJob
  queue_as :default

  HARDCODED_BLOCKED = %w[
    spam scam fake fraud cheat hack illegal bomb kill murder
    racist sexist hate offensive propaganda casino gambling
  ].freeze

  def perform(comment_id)
    comment = Comment.find_by(id: comment_id)
    return unless comment
    return if comment.status == 'flagged'

    blocked_words = load_blocked_words

    body_lower = comment.body.to_s.downcase
    flagged = blocked_words.any? { |word| body_lower.include?(word.downcase) }

    if flagged
      comment.update_columns(status: 'flagged')
      Rails.logger.info("CommentModerationJob - flagged comment #{comment.id}")
    end
  end

  private

  def load_blocked_words
    env_words = ENV.fetch('BLOCKED_WORDS', '').split(',').map(&:strip).reject(&:empty?)
    (HARDCODED_BLOCKED + env_words).uniq
  end
end
