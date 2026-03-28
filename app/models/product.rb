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
    BOOKING_COM = 'Booking.com',
    GOOD_BUYZ = 'Good Buyz',
    BEGINNING_BOUTIQUE = 'Beginning Boutique',
    UNIVERSAL_STORE = 'Universal Store',
    LORNA_JANE = 'Lorna Jane'
  ].freeze

  before_save :set_affiliate_network

  has_many :click_trackings, dependent: :destroy
  has_many :price_histories, dependent: :destroy
  has_many :price_alerts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :ai_deal_analysis, dependent: :destroy
  has_many :deal_ratings, dependent: :destroy
  has_many :collection_items, dependent: :destroy
  has_many :collections, through: :collection_items
  has_many :deal_reports, dependent: :destroy
  has_many :deal_score_histories, dependent: :destroy

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

  def avg_rating
    deal_ratings.average(:rating)&.to_f&.round(1) || 0.0
  end

  def rating_count
    deal_ratings.count
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

  def price_prediction_value
    return nil unless association(:price_histories).loaded?

    recent = price_histories.sort_by(&:recorded_at).reverse.first(5)
    return nil if recent.size < 3

    if recent.all? { |h| h.price <= price.to_f }
      'likely_to_drop'
    elsif recent.first&.price.to_f > price.to_f * 1.1
      'recently_dropped'
    end
  end

  def best_deal?
    avg = average_price_90_days
    return false if avg.nil? || avg.zero? || price.nil?

    price.to_f <= avg * 0.80
  end

  def ai_recommendation
    ai_deal_analysis&.recommendation
  end

  def ai_reasoning_short
    ai_deal_analysis&.reasoning&.truncate(120)
  end

  EXCHANGE_RATES = {
    'AUD' => 1.0,
    'USD' => 0.64,
    'GBP' => 0.51,
    'EUR' => 0.59,
    'NZD' => 1.08,
    'SGD' => 0.86,
    'CAD' => 0.87
  }.freeze

  CURRENCY_SYMBOLS = {
    'AUD' => 'A$',
    'USD' => '$',
    'GBP' => '£',
    'EUR' => '€',
    'NZD' => 'NZ$',
    'SGD' => 'S$',
    'CAD' => 'C$'
  }.freeze

  def freshness_score
    age = Time.current - created_at
    if age < 1.hour
      100
    elsif age < 6.hours
      80
    elsif age < 24.hours
      60
    elsif age < 3.days
      40
    else
      20
    end
  end

  alias recency_score freshness_score

  def deal_score
    # Only score if we have a meaningful discount or price history
    has_discount = discount.to_f > 0
    has_history  = price_histories.recent.exists?

    return 0 unless has_discount || has_history

    score = 0
    score += (discount.to_f / 10).clamp(0, 5)
    score += click_count > 10 ? 2 : (click_count.to_f / 5).clamp(0, 2)
    score += best_deal? ? 3 : 0
    score += (freshness_score / 100.0).clamp(0, 2)
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

  def heat_index
    raw = (view_count.to_f * 0.3 + upvotes.to_f * 0.5 + click_count.to_f * 0.2 + share_count.to_f * 0.4).round
    [raw, 9999].min
  end

  def upvotes
    votes.where(value: 1).count
  end

  AWIN_STORES = [ASOS, JD_SPORTS].freeze

  SHIPPING_DAYS = {
    ASOS             => '2-5 days',
    JD_SPORTS        => '3-7 days',
    MYER             => '3-5 days',
    OFFICE_WORKS     => '2-5 days',
    JB_HIFI          => '2-4 days',
    GLUE_STORE       => '3-7 days',
    NIKE             => '3-7 days',
    CULTURE_KINGS    => '3-7 days',
    THE_GOOD_GUYS    => '2-5 days',
    THE_ICONIC       => '2-4 days',
    KMART            => '3-7 days',
    BIG_W            => '3-7 days',
    TARGET_AU        => '3-7 days',
    BOOKING_COM      => nil,
    GOOD_BUYZ        => '5-10 days',
    BEGINNING_BOUTIQUE => '3-7 days',
    UNIVERSAL_STORE  => '3-7 days',
    LORNA_JANE       => '3-5 days'
  }.freeze
  AFFILIATE_RATES = {
    'awin' => 0.06,
    'commission_factory' => 0.04,
    'direct' => 0.0
  }.freeze

  def set_affiliate_network
    self.affiliate_network ||= AWIN_STORES.include?(store) ? 'awin' : 'commission_factory'
    self.commission_rate ||= AFFILIATE_RATES[affiliate_network] || 0.04
  end

  def affiliate_network_value
    return affiliate_network if affiliate_network.present?

    AWIN_STORES.include?(store) ? 'awin' : 'commission_factory'
  end

  def commission_rate_value
    return commission_rate.to_f if commission_rate.present?

    affiliate_network_value == 'awin' ? 0.06 : 0.04
  end

  def shipping_info
    # Use stored metadata first, fall back to static config
    stored = metadata&.dig('shipping_days')
    stored.presence || SHIPPING_DAYS[store]
  end

  def quality_score
    score = 0
    score += 20 if image_url.present?
    score += 20 if old_price.to_f > 0
    disc = discount.to_f
    score += 20 if disc > 20
    score += 10 if disc > 40
    score += 10 if name.to_s.length > 10
    score += 10 if brand.present?
    score += 10 if Array(categories).any?(&:present?)
    [score, 100].min
  end

  def aggregate_score
    raw = deal_score.to_f * 0.4 +
          heat_index.to_f * 0.3 +
          (view_count.to_f / 100.0) * 0.2 +
          (share_count.to_f * 2) * 0.1
    raw.clamp(0, 100).round(2)
  end

  def popularity_score
    days = [(Time.current - updated_at) / 1.day, 0].max
    decay = 1.0 / (1.0 + days)
    (heat_index.to_f * decay).round(4)
  end

  # Parse bundle quantity from product name
  # Handles: "2 for $X", "Buy 2 get 1 free", "Twin pack", "3 Pack", "2-Pack"
  def detect_bundle_quantity
    n = name.to_s
    qty = if n =~ /\b(\d+)\s*for\s*\$?\d/i
      $1.to_i
    elsif n =~ /buy\s*(\d+)\s*get/i
      $1.to_i + 1
    elsif n =~ /\btwin\s*pack\b/i
      2
    elsif n =~ /\b(\d+)\s*[\-\s]?pack\b/i
      $1.to_i
    elsif n =~ /\bpack\s+of\s+(\d+)\b/i
      $1.to_i
    else
      1
    end
    [qty, 1].max
  end

  def computed_price_per_unit
    qty = bundle_quantity.to_i
    return nil unless qty > 1 && price.to_f > 0

    (price.to_f / qty).round(2)
  end

  def discount_tier
    pct = discount.to_f
    return nil unless pct > 0

    if pct >= 70
      'legendary'
    elsif pct >= 50
      'amazing'
    elsif pct >= 30
      'great'
    elsif pct >= 15
      'good'
    else
      'minor'
    end
  end

  SHOPIFY_CDN_PATTERN = /cdn\.shopify\.com/i

  def optimized_image_url
    return nil if image_url.blank?
    if image_url.match?(SHOPIFY_CDN_PATTERN)
      uri = URI.parse(image_url)
      existing = URI.decode_www_form(uri.query || '').to_h
      existing['width'] = '400'
      existing['format'] = 'webp'
      uri.query = URI.encode_www_form(existing)
      uri.to_s
    else
      image_url
    end
  rescue URI::InvalidURIError
    image_url
  end

  def as_json(options = {})
    currency_code = options.delete(:currency)
    base = super(options).merge(
      store_url:,
      click_count:,
      deal_score:,
      freshness_score:,
      recency_score:,
      view_count: view_count,
      share_count: share_count,
      heat_index: heat_index,
      aggregate_score: aggregate_score,
      affiliate_network: affiliate_network_value,
      image_urls: [image_url].compact,
      best_deal: best_deal?,
      tags: tags || [],
      price_trend: price_trend,
      is_bundle: is_bundle,
      bundle_quantity: bundle_quantity.to_i,
      price_per_unit: computed_price_per_unit,
      in_stock: in_stock,
      quality_score: quality_score,
      ai_recommendation: ai_recommendation,
      ai_confidence: ai_deal_analysis&.confidence,
      ai_reasoning_short: ai_reasoning_short,
      'discount' => discount.to_f,
      'old_price' => old_price.to_f,
      'price' => price.to_f,
      'flash_expires_at' => flash_expires_at,
      'updated_at' => updated_at.strftime(DATE_FORMAT),
      'created_at' => created_at.strftime(DATE_FORMAT),
      popularity_score: popularity_score,
      price_prediction: price_prediction_value,
      avg_rating: avg_rating,
      rating_count: rating_count,
      status: status.presence || (expired? ? 'expired' : 'active'),
      going_fast: going_fast,
      discount_tier: discount_tier,
      shipping_info: shipping_info,
      optimized_image_url: optimized_image_url
    )

    if currency_code && currency_code != 'AUD' && EXCHANGE_RATES.key?(currency_code)
      rate = EXCHANGE_RATES[currency_code]
      base['display_price']    = (price.to_f * rate).round(2)
      base['display_old_price'] = old_price.to_f > 0 ? (old_price.to_f * rate).round(2) : nil
      base['display_currency'] = currency_code
    end

    base
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
    when GOOD_BUYZ
      "https://goodbuyz.com.au#{store_path}"
    when UNIVERSAL_STORE
      "https://www.universalstore.com.au#{store_path}"
    when BEGINNING_BOUTIQUE
      "https://beginningboutique.com.au#{store_path}"
    when LORNA_JANE
      "https://www.lornajane.com.au#{store_path}"
    end
  end
end
