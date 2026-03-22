# frozen_string_literal: true

class Product < ApplicationRecord
  DATE_FORMAT = '%d/%m/%Y %H:%M:%S'
  STORES = [
    OFFICE_WORKS = 'Office Works',
    JB_HIFI = 'JB Hi-Fi',
    GLUE_STORE = 'Glue Store',
    NIKE = 'Nike',
    CULTURE_KINGS = 'Culture Kings',
    JD_SPORTS = 'JD Sports',
    MYER = 'Myer',
    THE_GOOD_GUYS = 'The Good Guys',
    ASOS = 'ASOS',
    THE_ICONIC = 'The Iconic',
    KMART = 'Kmart',
    BIG_W = 'Big W',
    TARGET_AU = 'Target AU',
    BOOKING_COM = 'Booking.com'
  ].freeze

  has_many :click_trackings, dependent: :destroy
  has_many :price_histories, dependent: :destroy
  has_many :price_alerts, dependent: :destroy
  has_one :ai_deal_analysis, dependent: :destroy

  validates :name, presence: true
  validates :price, presence: true
  validates :store_product_id, presence: true
  validates :store, presence: true

  class << self
    def brands
      pluck('DISTINCT(brand)')
    end

    def categories
      pluck('DISTINCT(categories)').flatten.uniq
    end

    def stores
      pluck('DISTINCT(store)')
    end
  end

  def click_count
    click_trackings.count
  end

  def average_price_90_days
    avg = price_histories.last_90_days.average(:price)
    avg&.to_f
  end

  def price_trend
    history = price_histories.recent.limit(5).pluck(:price)
    return :stable if history.size < 2

    latest = history.first.to_f
    older  = history.last.to_f
    return :stable if older.zero?

    diff = (latest - older) / older
    if diff <= -0.02
      :down
    elsif diff >= 0.02
      :up
    else
      :stable
    end
  end

  def best_deal?
    avg = average_price_90_days
    return false if avg.nil? || avg.zero? || price.nil?

    price.to_f <= avg * 0.80
  end

  def deal_score
    # Only score if we have a meaningful discount or price history
    has_discount = discount.to_f > 0
    has_history  = price_histories.recent.exists?

    return nil unless has_discount || has_history

    score = 0
    score += (discount.to_f / 10).clamp(0, 5)
    score += click_count > 10 ? 2 : (click_count.to_f / 5).clamp(0, 2)
    score += best_deal? ? 3 : 0
    score.round.clamp(1, 10)
  end

  def record_price_history!
    last = price_histories.recent.first
    return if last && last.price.to_f == price.to_f

    price_histories.create!(
      price: price,
      old_price: old_price,
      discount: discount,
      recorded_at: Time.current
    )
  end

  def as_json(options = {})
    super(options).merge(
      store_url:,
      click_count:,
      deal_score:,
      best_deal: best_deal?,
      price_trend: price_trend,
      ai_recommendation: ai_deal_analysis&.recommendation,
      ai_confidence: ai_deal_analysis&.confidence,
      ai_reasoning_short: ai_deal_analysis&.reasoning&.split('.')&.first,
      'discount' => discount.to_f,
      'old_price' => old_price.to_f,
      'price' => price.to_f,
      'updated_at' => updated_at.strftime(DATE_FORMAT),
      'created_at' => created_at.strftime(DATE_FORMAT)
    )
  end

  def store_url
    return if store_path.blank?

    case store
    when OFFICE_WORKS
      "https://www.officeworks.com.au#{store_path}"
    when JB_HIFI
      "https://www.jbhifi.com.au/products/#{store_path}"
    when GLUE_STORE
      "https://www.gluestore.com.au/products/#{store_path}"
    when NIKE
      "https://www.nike.com/#{store_path}"
    when CULTURE_KINGS
      "https://www.culturekings.com.au/products/#{store_path}"
    when JD_SPORTS
      "https://www.jd-sports.com.au#{store_path}"
    when MYER
      "https://www.myer.com.au/p/#{store_path}"
    when ASOS
      "https://www.asos.com/au/#{store_path}"
    when THE_ICONIC
      "https://www.theiconic.com.au#{store_path}"
    when THE_GOOD_GUYS
      store_path
    when KMART
      "https://www.kmart.com.au#{store_path}"
    when BIG_W
      "https://www.bigw.com.au#{store_path}"
    when TARGET_AU
      "https://www.target.com.au#{store_path}"
    when BOOKING_COM
      store_path
    end
  end
end
