# frozen_string_literal: true

class RecalculateDealScoresJob
  include Sidekiq::Job

  queue_as :default

  def perform
    products = Product.where(expired: false)
    now = Time.current

    products.find_each do |product|
      score = calculate_score(product)
      going_fast = product.view_count.to_i > 100 || product.click_count.to_i > 20
      product.update_columns(deal_score: score.round(2), going_fast: going_fast)
      DealScoreHistory.create!(
        product_id: product.id,
        score: score.round(2),
        recorded_at: now
      )
    end
  end

  private

  def calculate_score(product)
    discount_score = product.discount.to_f * 0.4

    # votes.value > 0 = upvote, < 0 = downvote
    upvotes   = Vote.where(product_id: product.id).where("value > 0").count
    downvotes = Vote.where(product_id: product.id).where("value < 0").count
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

    base = (base_score * 0.7 + recency * 0.3).round(2)

    rating_bonus = 0.0
    avg_r = product.avg_rating.to_f
    if avg_r > 0
      rating_bonus = ((avg_r - 3) * 5).clamp(-10.0, 10.0)
    end

    community_bonus = product.rating_count.to_i > 5 ? 3.0 : 0.0
    stock_penalty   = product.in_stock == false ? -20.0 : 0.0
    quality_bonus   = product.quality_score.to_f * 0.1

    (base + rating_bonus + community_bonus + stock_penalty + quality_bonus).round(2)
  end
end
