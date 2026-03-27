# frozen_string_literal: true

class RecalculateDealScoresJob
  include Sidekiq::Job

  queue_as :default

  def perform
    products = Product.where(expired: false)

    products.find_each do |product|
      score = calculate_score(product)
      product.update_columns(deal_score: score.round(2))
    end
  end

  private

  def calculate_score(product)
    discount_score = product.discount.to_f * 0.4

    upvotes = Vote.where(product_id: product.id, vote_type: 'up').count
    downvotes = Vote.where(product_id: product.id, vote_type: 'down').count
    total_votes = upvotes + downvotes
    vote_ratio = total_votes > 0 ? upvotes.to_f / total_votes : 0
    vote_score = vote_ratio * 30

    recency_bonus = product.created_at >= 24.hours.ago ? 10 : 0

    last_two = product.price_histories.order(recorded_at: :desc).limit(2).to_a
    price_drop_bonus = if last_two.size >= 2 && last_two.first.price < last_two.last.price
      5
    else
      0
    end

    discount_score + vote_score + recency_bonus + price_drop_bonus
  end
end
