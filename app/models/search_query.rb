class SearchQuery < ApplicationRecord
  validates :query, presence: true

  def self.track(query)
    return if query.blank? || query.length < 2

    q = query.strip.downcase.truncate(100)
    where(query: q).first_or_create!.increment!(:count)
  rescue => e
    Rails.logger.error "SearchQuery.track error: #{e.message}"
  end

  def self.trending(limit: 10)
    order(count: :desc).limit(limit)
  end
end
