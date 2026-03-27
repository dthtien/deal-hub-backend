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

    price_drop_bonus = 0
    last_two = product.price_histories.order(recorded_at: :desc).limit(2).to_a
    if last_two.size >= 2 && last_two.first.price < last_two.last.price
      price_drop_bonus = 5
    end

    base_score = discount_score + vote_score + price_drop_bonus
    recency = product.recency_score

    (base_score * 0.7 + recency * 0.3).round(2)
  end
end
