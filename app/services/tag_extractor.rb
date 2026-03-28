# frozen_string_literal: true

# Extracts relevant tags from product name + categories using keyword rules.
# Called during upsert_with_price_history for each product.
class TagExtractor
  ELECTRONICS_BRANDS = %w[apple samsung sony lg dell hp asus lenovo bose jbl canon nikon fujifilm
                           microsoft google huawei oppo xiaomi philips panasonic dyson].freeze
  MODEL_PATTERN = /\b([A-Z]{1,4}[\s-]?[\d]{3,6}[A-Za-z0-9\-]*)\b/.freeze

  FASHION_COLORS = %w[black white red blue green yellow pink purple grey gray navy cream beige
                       orange teal burgundy coral khaki].freeze
  FASHION_MATERIALS = %w[cotton linen silk wool leather denim polyester nylon spandex cashmere
                          satin velvet bamboo].freeze

  SPORTS_TYPES = %w[running cycling yoga gym football soccer basketball tennis cricket
                     swimming hiking camping climbing].freeze
  SPORTS_BRANDS = %w[nike adidas puma reebok under\ armour asics brooks new\ balance
                      lorna\ jane gym\ king].freeze

  ELECTRONICS_KEYWORDS = %w[electronic laptop phone audio tv gaming camera headphone speaker
                              tablet monitor computer printer router charger cable].freeze
  FASHION_KEYWORDS = %w[women men dress skirt shirt pants jeans jacket coat blouse top
                         activewear sportswear shoes sneaker boot sandal bag accessory].freeze
  SPORTS_KEYWORDS = %w[sport active outdoor gym yoga bike swim hike camp fishing].freeze

  def self.extract(name:, categories:)
    new(name: name, categories: categories).extract
  end

  def initialize(name:, categories:)
    @name_lower   = name.to_s.downcase
    @cats_lower   = Array(categories).map(&:downcase)
    @all_text     = "#{@name_lower} #{@cats_lower.join(' ')}"
    @tags         = []
  end

  def extract
    classify_and_tag
    @tags.uniq.first(10)
  end

  private

  def classify_and_tag
    if electronics?
      tag_electronics
    elsif fashion?
      tag_fashion
    elsif sports?
      tag_sports
    end
  end

  def electronics?
    ELECTRONICS_KEYWORDS.any? { |kw| @all_text.include?(kw) }
  end

  def fashion?
    FASHION_KEYWORDS.any? { |kw| @all_text.include?(kw) }
  end

  def sports?
    SPORTS_KEYWORDS.any? { |kw| @all_text.include?(kw) }
  end

  def tag_electronics
    ELECTRONICS_BRANDS.each do |brand|
      @tags << brand if @name_lower.include?(brand)
    end
    MODEL_PATTERN.match(@name_raw || '') { |m| @tags << m[1].strip }
    @tags << 'electronics'
  end

  def tag_fashion
    FASHION_COLORS.each { |c| @tags << c if @name_lower.include?(c) }
    FASHION_MATERIALS.each { |m| @tags << m if @name_lower.include?(m) }
    @tags << 'fashion'
  end

  def tag_sports
    SPORTS_TYPES.each { |t| @tags << t if @all_text.include?(t) }
    SPORTS_BRANDS.each { |b| @tags << b if @all_text.include?(b) }
    @tags << 'sports'
  end
end
