class SearchQuery < ApplicationRecord
  validates :query, presence: true

  def self.track(query, result_count: nil)
    return if query.blank? || query.length < 2

    q = query.strip.downcase.truncate(100)
    record = where(query: q).first_or_create!
    record.increment!(:count)
    if result_count
      record.increment!(:result_count_total, result_count)
      record.increment!(:search_count)
    end
  rescue => e
    Rails.logger.error "SearchQuery.track error: #{e.message}"
  end

  def self.trending(limit: 10)
    order(count: :desc).limit(limit)
  end

  def avg_result_count
    return nil if search_count.to_i.zero?
    (result_count_total.to_f / search_count).round(1)
  end
end
